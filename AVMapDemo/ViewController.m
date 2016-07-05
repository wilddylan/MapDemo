//
//  ViewController.m
//  AVMapDemo
//
//  Created by Dylan on 16/7/5.
//  Copyright © 2016年 Dylan. All rights reserved.
//

/**
 *  latitude  纬度
 *  longitude 经度
 */

#define CASE_COR CLLocationCoordinate2DMake(30.278500, 120.160466)

#import "ViewController.h"

@interface ViewController () <MAMapViewDelegate, AMapSearchDelegate, AMapNaviDriveManagerDelegate, AMapNaviDriveViewDelegate> {
    
    /**
     地图
     */
    MAMapView *_mapView;
    /**
     搜索引擎
     */
    AMapSearchAPI *_search;
    /**
     导航
     */
    AMapNaviDriveManager *_driveManager;
    AMapNaviDriveView *_naviDriveView;
    /**
     工具栏
     */
    UIToolbar *_toolBar;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Add the test case item.
    [self CASE];
    
    // 初始化地图
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 44)];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    // 展示当前用户的地理位置
    _mapView.showsUserLocation = YES;
    
    // 跟随用户的移动, 加Header则为跟随方向
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    
    // 设置地图缩放级别 3 ~ 19
    _mapView.zoomLevel = 17.5;
    
    // 关闭指南针显示
    _mapView.showsCompass= NO;
    
    // 关闭比例尺显示
    _mapView.showsScale = NO;
    
    // 这样设置地图中心点只会平移地图, 不会改变缩放级别
//    _mapView.centerCoordinate = CASE_COR;
    
    // 开启旋转 3D 旋转角度的范围是[0.f 360.f]，以逆时针为正向
    [_mapView setRotationDegree:60.f animated:YES duration:0.5];
    
    // 开启倾斜 3D 倾斜角度范围为[0.f, 45.f]
    [_mapView setCameraDegree:10.f animated:YES duration:0.5];
    
#pragma mark - POI检索
    
    // 初始化检索对象
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
    
#pragma mark - 导航
    
    _driveManager = [[AMapNaviDriveManager alloc] init];
    [_driveManager setDelegate:self];
}

#pragma mark - route delegate method

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager {
    
    //将naviDriveView添加到AMapNaviDriveManager中
    [_driveManager addDataRepresentative:_naviDriveView];
    
    //将导航视图添加到视图层级中
    [self.view addSubview:_naviDriveView];
    
    //开始实时导航
    [_driveManager startGPSNavi];
}

- (void)driveViewCloseButtonClicked:(AMapNaviDriveView *)driveView {
    //停止导航
    [_driveManager stopNavi];
    
    //将naviDriveView从AMapNaviDriveManager中移除
    [_driveManager removeDataRepresentative:_naviDriveView];
    
    //将导航视图从视图层级中移除
    [_naviDriveView removeFromSuperview];
}

- (void)driveManager:(AMapNaviDriveManager *)naviManager
 playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType {
    
    
    if (soundStringType == AMapNaviSoundTypePassedReminder) {
        AudioServicesPlaySystemSound(1009);//播放系统“叮叮”提示音
    }
    else {
        // 播放语音, 注意在停止导航的时候停止播报语音
        NSLog(@"%@", soundString);
    }
}

#pragma mark - search delegate method

- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response {
    
    if(response.pois.count == 0) {
        return;
    }
    
    //通过 AMapPOISearchResponse 对象处理搜索结果
    NSString *strCount = [NSString stringWithFormat:@"count: %ld",response.count];
    NSString *strSuggestion = [NSString stringWithFormat:@"Suggestion: %@", response.suggestion.keywords];
    NSString *strPoi = @"";
    for (AMapPOI *p in response.pois) {
        strPoi = [NSString stringWithFormat:@"%@\nPOI: %@", strPoi, p.name];
        
        NSString *result = [NSString stringWithFormat:@"%@ \n %@ \n %@", strCount, strSuggestion, strPoi];
        NSLog(@"Place: %@", result);
    }
}

- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response {
    
    if(response.route == nil) {
        return;
    }
    
    //通过AMapNavigationSearchResponse对象处理搜索结果
    
    
    if ( [request isKindOfClass:[AMapDrivingRouteSearchRequest class]] ||
         [request isKindOfClass:[AMapWalkingRouteSearchRequest class]] ) {
     
        // 步行或者驾车
        AMapRoute * route = response.route;
        [route.paths
         enumerateObjectsUsingBlock:^(AMapPath * obj, NSUInteger idx, BOOL * stop) {
             
             NSLog(@"--> %@", obj.strategy);
             [obj.steps
              enumerateObjectsUsingBlock:^(AMapStep * step, NSUInteger idx, BOOL * stop) {
                  
                  NSLog(@"%@", step.instruction);
             }];
        }];
        
    } else {
        
        // 公交
        AMapRoute * route = response.route;
        [route.transits
         enumerateObjectsUsingBlock:^(AMapTransit * obj, NSUInteger idx, BOOL * stop) {
            
            [obj.segments
             enumerateObjectsUsingBlock:^(AMapSegment * segment, NSUInteger idx, BOOL * stop) {
                
                 // 公交站点信息
                 [segment.buslines
                  enumerateObjectsUsingBlock:^(AMapBusLine * cc, NSUInteger idx, BOOL * stop) {
                      
                      NSLog(@"%@ - %@", cc.name, cc.type);
                 }];
                 
                 // 步行换乘
                 AMapWalking * walking = segment.walking;
                 
                 [walking.steps
                  enumerateObjectsUsingBlock:^(AMapStep * step, NSUInteger idx, BOOL * stop) {
                      
                      NSLog(@"%@", step.instruction);
                  }];
            }];
        }];
    }
}

//实现正向地理编码的回调函数
- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response {
    
    if(response.geocodes.count == 0) {
        return;
    }
    
    //通过AMapGeocodeSearchResponse对象处理搜索结果
    for (AMapGeocode *p in response.geocodes) {
        NSLog(@"Geocode: %@", p.formattedAddress);
    }
}

//实现逆地理编码的回调函数
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
    
    if(response.regeocode != nil) {
        
        //通过AMapReGeocodeSearchResponse对象处理搜索结果
        NSLog(@"ReGeo: %@", response.regeocode.formattedAddress);
    }
}

//实现输入提示的回调函数
-(void)onInputTipsSearchDone:(AMapInputTipsSearchRequest*)request response:(AMapInputTipsSearchResponse *)response {
    
    if(response.tips.count == 0) {
        return;
    }
    
    //通过AMapInputTipsSearchResponse对象处理搜索结果
    for (AMapTip *p in response.tips) {
        NSLog(@"%@-%@", p.name, p.address);
    }
}

#pragma mark - map delegate method

-(void)mapView:(MAMapView *)mapView
didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL) updatingLocation {
    
    if(updatingLocation) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
                _mapView.centerCoordinate = userLocation.location.coordinate;
        });
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        MAAnnotationView *annotationView = (MAAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil) {
            
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:reuseIndetifier];
        }
        annotationView.image = [UIImage imageNamed:@"company"];
        //设置中心点偏移，使得标注底部中间点成为经纬度对应点
        annotationView.centerOffset = CGPointMake(0, -12);
        return annotationView;
    }
    return nil;
}

#pragma mark - delegate method

- (void) CASE {
    
    // Operate
    
    UIBarButtonItem * map_Traffic = [[UIBarButtonItem alloc] initWithTitle:@"Traffic" style:UIBarButtonItemStylePlain target:self action:@selector(showTrafficAction)];
    UIBarButtonItem * map_POI = [[UIBarButtonItem alloc] initWithTitle:@"POI" style:UIBarButtonItemStylePlain target:self action:@selector(POIAction)];
    UIBarButtonItem * map_Route = [[UIBarButtonItem alloc] initWithTitle:@"Route" style:UIBarButtonItemStylePlain target:self action:@selector(RouteAction)];
    UIBarButtonItem * map_Foot = [[UIBarButtonItem alloc] initWithTitle:@"Foot" style:UIBarButtonItemStylePlain target:self action:@selector(FootAction)];
    UIBarButtonItem * map_Bus = [[UIBarButtonItem alloc] initWithTitle:@"Bus" style:UIBarButtonItemStylePlain target:self action:@selector(BusAction)];
    UIBarButtonItem * map_Geo = [[UIBarButtonItem alloc] initWithTitle:@"Geo" style:UIBarButtonItemStylePlain target:self action:@selector(GeoAction)];
    UIBarButtonItem * map_DeGeo = [[UIBarButtonItem alloc] initWithTitle:@"DeGeo" style:UIBarButtonItemStylePlain target:self action:@selector(DeGeoAction)];
    UIBarButtonItem * map_Tip = [[UIBarButtonItem alloc] initWithTitle:@"Tip" style:UIBarButtonItemStylePlain target:self action:@selector(TipAction)];
    
    self.navigationItem.leftBarButtonItems = @[map_Traffic, map_POI, map_Route, map_Foot, map_Bus, map_Geo, map_DeGeo, map_Tip];
    
    // Annotation
    [self performSelector:@selector(Annotation) withObject:nil afterDelay:5];
    
    UIBarButtonItem * R_Route = [[UIBarButtonItem alloc] initWithTitle:@"R_Route" style:UIBarButtonItemStylePlain target:self action:@selector(R_RAction)];
    
    // Toor Bar
    _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 44 - 64, CGRectGetWidth(self.view.frame), 44)];
    [_toolBar setItems:@[R_Route] animated:YES];
    [self.view addSubview:_toolBar];    
}

- (void) showTrafficAction {
    
    // 是否显示交通
    _mapView.showTraffic = !_mapView.showTraffic;
}

- (void) Annotation {
    
#pragma mark 增加点
    
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = CASE_COR;
    // 增加标注点, 如果不实现`viewForAnnotation`代理方法, 默认为红色的pin
    [_mapView addAnnotation:pointAnnotation];
}

- (void) POIAction {
    
#pragma mark POI 搜索
    // 初始化搜索请求
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:CASE_COR.latitude longitude:CASE_COR.longitude];
    request.keywords = @"钱江科技大厦";
    // types属性表示限定搜索POI的类别，默认为：餐饮服务|商务住宅|生活服务
    // 汽车服务|汽车销售|汽车维修|摩托车服务|餐饮服务|购物服务|生活服务|体育休闲服务|
    // 医疗保健服务|住宿服务|风景名胜|商务住宅|政府机构及社会团体|科教文化服务|
    // 交通设施服务|金融保险服务|公司企业|道路附属设施|地名地址信息|公共设施
    request.types = @"商务住宅|地名地址信息|公共设施";
    // 排序方式
    request.sortrule = 0;
    // 是否返回扩展信息
    request.requireExtension = YES;
    
    [_search AMapPOIAroundSearch: request];
}

- (void) RouteAction {
    
#pragma mark 驾车路线
    
    //构造AMapDrivingRouteSearchRequest对象，设置驾车路径规划请求参数
    AMapDrivingRouteSearchRequest *request = [[AMapDrivingRouteSearchRequest alloc] init];
    // 初始位置
    request.origin = [AMapGeoPoint locationWithLatitude:_mapView.userLocation.coordinate.latitude longitude:_mapView.userLocation.coordinate.longitude];
    // 目的位置
    request.destination = [AMapGeoPoint locationWithLatitude:CASE_COR.latitude longitude:CASE_COR.longitude];
    /// 驾车导航策略：0-速度优先（时间）；1-费用优先（不走收费路段的最快道路）；2-距离优先；3-不走快速路；4-结合实时交通（躲避拥堵）；5-多策略（同时使用速度优先、费用优先、距离优先三个策略）；6-不走高速；7-不走高速且避免收费；8-躲避收费和拥堵；9-不走高速且躲避收费和拥堵
    request.strategy = 2;
    // 是否返回扩展信息
    request.requireExtension = YES;
    
    [_search AMapDrivingRouteSearch:request];
}

- (void) FootAction {
    
#pragma mark 步行路线
    AMapWalkingRouteSearchRequest * request = [[AMapWalkingRouteSearchRequest alloc] init];
    
    request.origin = [AMapGeoPoint locationWithLatitude:_mapView.userLocation.coordinate.latitude longitude:_mapView.userLocation.coordinate.longitude];
    request.destination = [AMapGeoPoint locationWithLatitude:CASE_COR.latitude longitude:CASE_COR.longitude];
    
    [_search AMapWalkingRouteSearch:request];
}

- (void) BusAction {
    
#pragma mark 公交路线
    AMapTransitRouteSearchRequest * request = [[AMapTransitRouteSearchRequest alloc] init];
    
    request.origin = [AMapGeoPoint locationWithLatitude:_mapView.userLocation.coordinate.latitude longitude:_mapView.userLocation.coordinate.longitude];
    request.destination = [AMapGeoPoint locationWithLatitude:CASE_COR.latitude longitude:CASE_COR.longitude];
    
    /// 公交换乘策略：0-最快捷模式；1-最经济模式；2-最少换乘模式；3-最少步行模式；4-最舒适模式；5-不乘地铁模式
    request.strategy = 0;
    // 城市 必填
    request.city = @"杭州市";
    request.requireExtension = YES;
    
    [_search AMapTransitRouteSearch:request];
}

- (void) GeoAction {
    
#pragma mark 地理编码
    //构造AMapGeocodeSearchRequest对象，address为必选项，city为可选项
    AMapGeocodeSearchRequest *geo = [[AMapGeocodeSearchRequest alloc] init];
    geo.address = @"钱江科技大厦";
    //geo.city // 可选
    
    //发起正向地理编码
    [_search AMapGeocodeSearch:geo];
}

- (void) DeGeoAction {
    
#pragma mark 逆地理编码
    //构造AMapReGeocodeSearchRequest对象
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:_mapView.userLocation.coordinate.latitude longitude:_mapView.userLocation.coordinate.longitude];
    regeo.radius = 10000;
    regeo.requireExtension = YES;
    
    //发起逆地理编码
    [_search AMapReGoecodeSearch: regeo];
}

- (void) TipAction {
    
#pragma mark 输入提示
    //构造AMapInputTipsSearchRequest对象，设置请求参数
    AMapInputTipsSearchRequest *tipsRequest = [[AMapInputTipsSearchRequest alloc] init];
    tipsRequest.keywords = @"肯德基";
    tipsRequest.city = @"杭州";
    
    //发起输入提示搜索
    [_search AMapInputTipsSearch: tipsRequest];
}

- (void) R_RAction {
    
    
    if ( !_naviDriveView ) {
     
        // 初始化导航视图, 使用另一种样式 : AMapNaviHUDView
        _naviDriveView = [[AMapNaviDriveView alloc]
                          initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 44)];
        _naviDriveView.delegate = self;
    }
    
    AMapNaviPoint *startPoint = [AMapNaviPoint locationWithLatitude:_mapView.userLocation.coordinate.latitude longitude:_mapView.userLocation.coordinate.longitude];
    AMapNaviPoint *endPoint = [AMapNaviPoint locationWithLatitude:CASE_COR.latitude longitude:CASE_COR.longitude];
    
    NSArray *startPoints = @[startPoint];
    NSArray *endPoints   = @[endPoint];
    
//    // 关闭智能播报
//    [_driveManager setDetectedMode:AMapNaviDetectedModeNone];
    // 智能播报
    [_driveManager setDetectedMode:AMapNaviDetectedModeCameraAndSpecialRoad];
    //iOS9(含)以上系统需设置
    [_driveManager setAllowsBackgroundLocationUpdates:YES];
    //驾车路径规划（未设置途经点、导航策略为速度优先）
    [_driveManager calculateDriveRouteWithStartPoints:startPoints endPoints:endPoints wayPoints:nil drivingStrategy:AMapNaviDrivingStrategyDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
