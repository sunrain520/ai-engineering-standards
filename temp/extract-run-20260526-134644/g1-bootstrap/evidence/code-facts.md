---
doc_id: "app-client-android-bootstrap-evidence-code-facts"
title: "App-Client Android 启动与 SDK 装配 — 代码事实证据"
domain: "app-client"
sub_domain: "android"
doc_type: "evidence"
evidence_kind: "code-fact"
status: "draft"
indexable: true
source_batch: "app-client-android-app-bootstrap-app-kaz-p1, app-client-android-app-core-bootstrap-p1"
last_reviewed: "2026-05-26"
sanitized: true
---

# 代码事实证据（G1 Bootstrap）

> 编号空间：`EV-APP-CLIENT-G1-*`。所有路径均相对项目根，已脱敏；不含任何 SDK key/secret/token/license 实值。

## EV-APP-CLIENT-G1-1
- observed_pattern: 宿主 Application 子类继承 `HsApplication`，由 `app-kaz/src/main/AndroidManifest.xml` 的 `<application android:name="...global.GlobalApplication">` 显式注册
- file_role: app-host-application
- boundary: app-kaz 模块（宿主），不允许 app-core 或 common 直接继承
- confidence: high
- occurrences: 2（GlobalApplication.kt + AndroidManifest.xml）
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`、`app-kaz/src/main/AndroidManifest.xml`

## EV-APP-CLIENT-G1-2
- observed_pattern: `attachBaseContext` 中调用 `BaseApp.init(BuildConfig.DEBUG, false)` 在 `super.attachBaseContext` 之前完成 debug 标志注入
- file_role: app-host-application
- boundary: 宿主 Application；attachBaseContext 阶段只允许做最轻量的标志位初始化
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-3
- observed_pattern: `onCreate` 通过 `isHostProcess` 区分宿主进程与子进程，子进程仅初始化 `AndroidConfig`、`BuildConfigs`、`HsConfiguration.configureOfSubprocess` 后直接 return，避免子进程重复装配 RN/Push/EventBus
- file_role: app-host-application
- boundary: 宿主进程与子进程边界
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-4
- observed_pattern: 主进程初始化顺序固定为 `EventBus.register → ARouter.init(initRouter) → AndroidConfig.init → initBuildConfigs → RnRuntimeInitializer.ensureInitialized → initConfig → initLogTrace → initPush → 语言/Skin/NetworkManager → initCommonBiz → onHostCreate → AppInitializer.start → AppsFlyerIniter.init`
- file_role: bootstrap-orchestration
- boundary: 宿主进程 onCreate
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-5
- observed_pattern: ARouter 初始化封装在 `initRouter()` 中：debug 包先 `ARouter.openLog()`，随后 `ARouter.init(this)`；调用点早于 `RnRuntimeInitializer.ensureInitialized` 与业务初始化
- file_role: sdk-init-router
- boundary: 宿主主进程；不在子进程或 attachBaseContext 中初始化
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-6
- observed_pattern: `HsConfiguration.get().addInterceptor(TradeBaseParamInterceptor())` 与匿名 `Interceptor`（注入 `client-trace-id`）以及 `addEndInterceptor`（统一上报 `ApiError`）构成网络初始化三段式
- file_role: sdk-init-network
- boundary: 网络层（HsConfiguration），不在 OkHttp 直接调用层
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-7
- observed_pattern: 神策插件在 build.gradle 顶部声明：`apply plugin: 'com.sensorsdata.analytics.android'` 并 `apply from: "./gradle/sensors_settings.gradle"`；`sensor_scheme` 通过 `manifestPlaceholders` 在每个 buildType 注入；AndroidManifest 中存在 `com.sensorsdata.analytics.android.sdk.dialog.SchemeActivity` 声明
- file_role: sdk-config-sensors
- boundary: 构建期插件 + AndroidManifest 注册
- confidence: high
- occurrences: 3（build.gradle 三处 + AndroidManifest 一处）
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/build.gradle`、`app-kaz/src/main/AndroidManifest.xml`

## EV-APP-CLIENT-G1-8
- observed_pattern: `apply plugin: 'com.huawei.agconnect'` + 条件性 `com.google.gms.google-services`（仅当 `google-services.json` 存在）；AndroidManifest 中 `com.huawei.agconnect.AccessNetwork` meta-data 显式设为 `false`，要求隐私政策同意前不请求网络
- file_role: sdk-config-hms
- boundary: 构建期插件 + AndroidManifest meta-data
- confidence: high
- occurrences: 3
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/build.gradle`、`app-kaz/src/main/AndroidManifest.xml`

## EV-APP-CLIENT-G1-9
- observed_pattern: `apply plugin: 'com.google.devtools.ksp'` + 条件 `apply plugin: 'android.aop'`（debug-like 默认禁用，受 `hs.enableAndroidAop` 控制）；`androidAopConfig { include 'com.alibaba.android.arouter' }` 把 AOP 扫描范围限定到 ARouter 包
- file_role: build-plugin-aop
- boundary: 构建期；运行期不引入 AOP runtime 决策
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

## EV-APP-CLIENT-G1-10
- observed_pattern: `kapt` 配置带 `arg("AROUTER_MODULE_NAME", project.getName())`，且 `kapt Deps.Lib.arouter_compiler` 与 `ksp Deps.Lib.android_aop_processor` 共存
- file_role: build-annotation-processing
- boundary: 构建期；ARouter 走 kapt，AndroidAOP 走 KSP
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

## EV-APP-CLIENT-G1-11
- observed_pattern: `initPush()` 调用 `PushBus.init(this, S_android, S_agentIdValue, S_agentIdValue, 1) { ... HUAWEI 厂商判断 + GrayScaleManager 灰度判断 }`；随后 `Param.setDeviceNo`、`SocketHelper.get().setSocketPrint`、`setSocketPushListener`、`PushBusHelper.register(PushBusSubscriber.get())`
- file_role: sdk-init-push
- boundary: 宿主主进程；Push 初始化必须在 `initLogTrace()` 之后
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-12
- observed_pattern: AndroidManifest 中三类 Push Service 同时注册：`com.hstong.app_core.push.HsHuaweiMessageService`（`com.huawei.push.action.MESSAGING_EVENT`）、`com.hstong.app_core.push.PushFirebaseMessagingService`（`com.google.firebase.MESSAGING_EVENT`）、`com.hstong.app_core.push.HsAliPushReceiver`（阿里云三个 action）
- file_role: manifest-push-services
- boundary: AndroidManifest application 节点
- confidence: high
- occurrences: 3
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/AndroidManifest.xml`

## EV-APP-CLIENT-G1-13
- observed_pattern: `com.alibaba.app.appkey` 与 `com.alibaba.app.appsecret` 通过 `${aliPushAppKey}`、`${aliPushAppSecret}` 占位符注入，不在源码中硬编码
- file_role: manifest-sdk-credentials
- boundary: AndroidManifest meta-data；实际值由构建变量提供
- confidence: high
- occurrences: 2
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/AndroidManifest.xml`

## EV-APP-CLIENT-G1-14
- observed_pattern: `application` 节点禁用 `allowBackup="false"`，启用 `largeHeap="true"`，`networkSecurityConfig="${network_security_config}"` 由 buildType 注入（release 用 `network_security_config`，debug/beta/feature 用 `network_security_config_debug`）
- file_role: manifest-application-attrs
- boundary: AndroidManifest application 节点 + build.gradle manifestPlaceholders
- confidence: high
- occurrences: 5
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/AndroidManifest.xml`、`app-kaz/build.gradle`

## EV-APP-CLIENT-G1-15
- observed_pattern: 在 `onCreate` 末尾调用 `AppsFlyerIniter.init()`，置于 RN/网络/Push/语言/业务全部就绪之后
- file_role: sdk-init-attribution
- boundary: 宿主主进程末段；不与首屏渲染关键路径耦合
- confidence: medium
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-16
- observed_pattern: `onConfigurationChanged` 同步 `LanguageTool.initLocale` + `initActivityLocale` + `EventBus.post(newConfig)`，且仅在 `isHostProcess` 时调用 `AppLifecycleServiceManager.onConfigurationChanged`
- file_role: app-lifecycle
- boundary: 宿主 Application 生命周期回调
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-17
- observed_pattern: 启动闪屏 `Loading` 标注 `@Route(path = Router.ACTIVITY_SPLASH)`，在 `onCreate` 内置首字段为 `AcpConfig.appNormalLaunch = true`，并调用 `installSplashScreen()` 仅当 `Build.VERSION.SDK_INT >= S`
- file_role: launch-splash
- boundary: app-core 闪屏；不直接做业务
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/loading/Loading.kt`

## EV-APP-CLIENT-G1-18
- observed_pattern: 隐私协议未同意时 `Loading` 弹出 `TreatyDialog`，仅在用户点击 OK 后才调用 `HsConfiguration.get().onPrivacyGranted(application)` 与 `LogTrace.initLogTrace`、`SensorsDataAPI.sharedInstance().trackAppInstall`
- file_role: privacy-gate
- boundary: 闪屏；隐私同意前禁止启用任何主动上报或网络初始化
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/loading/Loading.kt`

## EV-APP-CLIENT-G1-19
- observed_pattern: `MainActivity` 的初始化顺序是 `setContentView → StatusBarUtil.setFullScreenStatusBar → ViewModelProvider 三个 ViewModel → bindViews → observeViewModel → initTabs → resolveSavedInstanceState → NewWhiteListApi.init → EventBus.register → MainStartConfigHelper.start → registerUpdateDialogDismissCallback → positionRectangleIndicator → accountStatusViewModel.refresh → checkLocalApkUpdateOnCreate`
- file_role: main-activity-bootstrap
- boundary: app-core 主页面 onCreate
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

## EV-APP-CLIENT-G1-20
- observed_pattern: Tab 列表唯一来源是 `BuildMainTabsUseCase()(hideTradeTab)`；Tab 渲染走 `tabList → TabItemData → HSTabBar.setTabItems`；Fragment 通过 `supportFragmentManager.fragmentFactory.instantiate(classLoader, tab.fragmentClass.name)` 实例化，避免直接 `new`
- file_role: main-tab-assembly
- boundary: MainActivity 与 BuildMainTabsUseCase 之间
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

## EV-APP-CLIENT-G1-21
- observed_pattern: 升级检查 `checkLocalApkUpdateOnCreate` 通过 KMP `AppUpgradePresenterFactory.createPresenter()` 计算 UIState，再通过反射桥接调用 `com.hstong.core.updataapk.LocalApkUpdateCapability` 的 `setUpdateDialogDismissCallback` / `isUpdateDialogShowing`，并显式跳过 Google 渠道
- file_role: update-bridge
- boundary: app-core 不直接依赖 updata-apk module；通过反射桥接
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

## EV-APP-CLIENT-G1-22
- observed_pattern: build.gradle 中 `if (rootProject.flavorGoogle) { configurations.configureEach { exclude group: 'io.github.azhon', module: 'appupdate' } }` 显式禁止 Google 渠道引入本地 APK 更新依赖
- file_role: flavor-guardrail
- boundary: 构建期依赖配置
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

## EV-APP-CLIENT-G1-23
- observed_pattern: `MainActivity.onCreate` 内 `if (isAbnormalStart()) return` 提前拦截异常重启场景，避免 Tab 与 ViewModel 初始化在异常恢复路径上重复触发
- file_role: abnormal-start-guard
- boundary: app-core 主 Activity 入口
- confidence: medium
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

## EV-APP-CLIENT-G1-24
- observed_pattern: `MainActivity.onResume` 在升级弹窗未展示时通过 `drainPendingPopupEffects()` 恢复因升级弹窗滞后的业务弹窗，强制升级期间 pending 队列保持等待
- file_role: popup-priority
- boundary: app-core 主 Activity；升级弹窗优先级高于其它业务弹窗
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

## EV-APP-CLIENT-G1-25
- observed_pattern: AndroidManifest 引入 `enableManifestExportedCheck` 插件（`com.hstong.plugin.chris.manifest-exported-check`），仅在非 debug-like 构建启用，并在 `exported { actionRules = ["android.intent.action.MAIN"]; enableMainManifest false }` 显式声明白名单
- file_role: manifest-security-guardrail
- boundary: 构建期
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

## EV-APP-CLIENT-G1-26
- observed_pattern: AndroidManifest 中 `<uses-library android:name="com.google.android.maps" android:required="false" />` 与 `android.test.runner` 同时声明在 application 节点内
- file_role: manifest-uses-library
- boundary: AndroidManifest application 节点
- confidence: medium
- occurrences: 2
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/AndroidManifest.xml`

## EV-APP-CLIENT-G1-27
- observed_pattern: 存在敏感配置文件 `app-kaz/google-services.json`、`app-kaz/agconnect-services.json`，且 build.gradle 用 `if (file("$projectDir/google-services.json").exists())` 守卫 GMS 插件，源码中无此两文件路径或字段值的引用
- file_role: sensitive-config-existence
- boundary: 构建期；运行期不读取
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true (existence only)
- 路径模式: `app-kaz/google-services.json`、`app-kaz/agconnect-services.json`、`app-kaz/build.gradle`

## EV-APP-CLIENT-G1-28
- observed_pattern: `compileOptions { coreLibraryDesugaringEnabled true; sourceCompatibility JavaVersion.VERSION_17; targetCompatibility JavaVersion.VERSION_17 }` 与 `kotlinOptions { jvmTarget = '17' }` 在 build.gradle 中并存
- file_role: build-toolchain
- boundary: 构建期
- confidence: high
- occurrences: 2
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

## EV-APP-CLIENT-G1-29
- observed_pattern: `onTerminate()` 显式 `EventBus.getDefault().unregister(this)` + `PushBusHelper.unregister(this)`；`exit()` 同步 `BusProxy.post(ExitEvent())`、`StatisticsUtils.saveData()`、`ThirdPushManager.get().setNotificationPushEnable(true)`、`onDataPersistence()`、`LanguageTool.unregisterLanReceiver(this)`
- file_role: app-teardown
- boundary: 宿主 Application 退出与销毁路径
- confidence: high
- occurrences: 2
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

## EV-APP-CLIENT-G1-30
- observed_pattern: `MainTabViewModel` 把 Tab 列表构建（`BuildMainTabsUseCase`）和返回退出节流（`HandleBackPressUseCase`）作为构造参数注入，View 层只调用 `onBackPressed(now)` 接收 `BackPressUiAction`，Activity 不再持有节流时间戳
- file_role: viewmodel-bootstrap
- boundary: app-core MVVM 边界
- confidence: high
- occurrences: 1
- evidence_kind: code-fact
- sanitized: true
- 路径模式: `app-core/src/main/**/main/mvvm/MainTabViewModel.kt`
