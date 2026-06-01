---
doc_id: "app-client-android-bootstrap-evidence-positive"
title: "App-Client Android 启动与 SDK 装配 — 正例证据"
domain: "app-client"
sub_domain: "android"
doc_type: "evidence"
evidence_kind: "positive-example"
status: "draft"
indexable: true
source_batch: "app-client-android-app-bootstrap-app-kaz-p1, app-client-android-app-core-bootstrap-p1"
last_reviewed: "2026-05-26"
sanitized: true
---

# 正例证据（G1 Bootstrap）

> 编号空间：`POS-APP-CLIENT-G1-*`。代码片段已脱敏，路径相对项目根。

## POS-APP-CLIENT-G1-1
- observed_pattern: 子进程在主进程初始化前提前 return，避免重复装配
- file_role: app-host-application
- boundary: 宿主 Application onCreate
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

```kotlin
override fun onCreate() {
    super.onCreate()
    HSUserManager.resetAndroidOnly()
    if (!isHostProcess) {
        AndroidConfig.init(this)
        initBuildConfigs()
        HsConfiguration.get().configureOfSubprocess(this)
        return
    }
    EventBus.getDefault().register(this)
    initRouter()
    AndroidConfig.init(this)
    initBuildConfigs()
    RnRuntimeInitializer.ensureInitialized(this)
    initConfig()
    // ...
}
```

## POS-APP-CLIENT-G1-2
- observed_pattern: ARouter 仅在 debug 包打开 log，避免 release 包暴露内部路由信息
- file_role: sdk-init-router
- boundary: 宿主 Application
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

```kotlin
private fun initRouter() {
    if (com.huasheng.base.app.BaseApp.isDebug()) {
        ARouter.openLog()
    }
    ARouter.init(this)
}
```

## POS-APP-CLIENT-G1-3
- observed_pattern: Push SDK 注册后通过统一回调把 socket 推送埋点接入 EventTracker，不在业务层自己拼日志
- file_role: sdk-init-push
- boundary: 宿主 Application initPush
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

```kotlin
SocketHelper.get().setSocketPrint { tag, map ->
    if (!tag.isNullOrEmpty() && !map.isNullOrEmpty()) {
        EventTracker.create(tag).put("startService", map).send()
    }
}
PushBusHelper.register(PushBusSubscriber.get())
```

## POS-APP-CLIENT-G1-4
- observed_pattern: 网络层统一在 `HsConfiguration` 注入 `client-trace-id`，让所有 KMP/Android 网络请求共享同一条链路标识
- file_role: sdk-init-network
- boundary: 宿主 Application initConfig
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`

```kotlin
HsConfiguration.get().addInterceptor(TradeBaseParamInterceptor())
HsConfiguration.get().addInterceptor(Interceptor { chain ->
    val newBuild = chain!!.request().newBuilder()
    newBuild.addHeader("client-trace-id", generateTraceId())
    chain.proceed(newBuild.build())
})
```

## POS-APP-CLIENT-G1-5
- observed_pattern: AndroidAOP 通过 `include` 把扫描范围严格限定到 ARouter 包，避免无关包参与切面分析
- file_role: build-plugin-aop
- boundary: 构建期
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

```groovy
androidAopConfig {
    enabled true
    include 'com.alibaba.android.arouter'
    exclude 'kotlin.jvm', 'kotlin.internal',
            'kotlinx.coroutines.internal', 'kotlinx.coroutines.android'
    verifyLeafExtends false
    cutInfoJson true
}
```

## POS-APP-CLIENT-G1-6
- observed_pattern: GMS 插件按文件存在性条件加载，便于无 google-services.json 的渠道（华为/海外灰度）正常构建
- file_role: build-plugin-gms
- boundary: 构建期
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

```groovy
apply plugin: 'com.huawei.agconnect'
if (file("$projectDir/google-services.json").exists()) {
    apply plugin: 'com.google.gms.google-services'
}
apply plugin: 'com.sensorsdata.analytics.android'
apply from: "./gradle/sensors_settings.gradle"
```

## POS-APP-CLIENT-G1-7
- observed_pattern: Sensor scheme、网络安全配置通过 `manifestPlaceholders` 在每个 buildType 注入，源码与 AndroidManifest 不写死
- file_role: build-manifest-placeholder
- boundary: 构建期
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/build.gradle`

```groovy
release {
    manifestPlaceholders = [
        sensor_scheme          : 'sa******',
        network_security_config: "@xml/network_security_config"
    ]
}
```

## POS-APP-CLIENT-G1-8
- observed_pattern: Loading 闪屏严格按"未同意隐私 → 仅展示协议；同意后才初始化 LogTrace 与神策"流程
- file_role: privacy-gate
- boundary: 闪屏 Activity
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-core/src/main/**/loading/Loading.kt`

```kotlin
private fun performGrantedWorking(first: Boolean) {
    if (Router.getTempProvider().isDeviceRooted(this)) return
    Router.getTempProvider().onPreAgreePrivacyPolicy(true)
    HmsInstanceId.getInstance(applicationContext)
    if (first) {
        HsConfiguration.get().onPrivacyGranted(application)
        LogTrace.initLogTrace(application, BaseApp.isDebug())
        sensorCheckAppInstall()
    }
    // ...
}
```

## POS-APP-CLIENT-G1-9
- observed_pattern: MainActivity 全部 Tab 信息从 `BuildMainTabsUseCase` 汇总后再调用 `setTabBarItems` / `setupViewPager`，View 层不直接持有 Tab 字面量
- file_role: main-tab-assembly
- boundary: app-core 主 Activity
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

```kotlin
private fun initTabs(savedInstanceState: Bundle?) {
    val hideTradeTab = AppAgentUtils.isHideTransactionAndOpenAccountAgent()
    val tabs = BuildMainTabsUseCase()(hideTradeTab)
    val savedTabId = savedInstanceState?.getString(MainKeyPool.STATE_TAB_ID)
    val initTabIndex = getTabIndex(savedTabId ?: initTab, tabs)
    tabList.clear(); tabList.addAll(tabs); tabFragments.clear()
    setupTabBarItems()
    setupViewPager(initTabIndex)
    setupTabListeners(initTabIndex)
    initTab = null
}
```

## POS-APP-CLIENT-G1-10
- observed_pattern: 升级弹窗与业务弹窗优先级解耦：先排队，等 BizPopupStack 就绪后统一 drain
- file_role: popup-priority
- boundary: app-core 主 Activity
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

```kotlin
private fun handlePopupEffect(effect: MainPopupEffect) {
    if (!bizPopupReady) {
        pendingPopupEffects.add(effect)
        return
    }
    if (deferPopupEffectIfUpgradeShowing(effect)) return
    dispatchPopupEffect(effect)
}
```

## POS-APP-CLIENT-G1-11
- observed_pattern: app-core 通过反射桥接调用 `LocalApkUpdateCapability`，避免对仅在非 Google 渠道装配的 module 直接静态依赖
- file_role: update-bridge
- boundary: app-core 与 capability 之间
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-core/src/main/**/main/MainActivity.kt`

```kotlin
private fun registerUpdateDialogDismissCallback() {
    runCatching {
        val clazz = Class.forName(LOCAL_APK_UPDATE_CAPABILITY_CLASS)
        val method = clazz.getMethod("setUpdateDialogDismissCallback", Runnable::class.java)
        method.invoke(null, Runnable {
            popupDrainHandler.post { drainPendingPopupEffects() }
        })
    }
}
```

## POS-APP-CLIENT-G1-12
- observed_pattern: AndroidManifest 把 GMS/HMS 推送 Service 显式声明 `exported="false"`，并配齐 intent-filter
- file_role: manifest-push-services
- boundary: AndroidManifest application 节点
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/src/main/AndroidManifest.xml`

```xml
<service
    android:name="com.hstong.app_core.push.HsHuaweiMessageService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.huawei.push.action.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## POS-APP-CLIENT-G1-13
- observed_pattern: HMS Analytics Kit 在隐私同意前禁用网络访问，通过 meta-data 在 manifest 层固化
- file_role: sdk-config-hms
- boundary: AndroidManifest application 节点
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-kaz/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.huawei.agconnect.AccessNetwork"
    android:value="false" />
```

## POS-APP-CLIENT-G1-14
- observed_pattern: `MainTabViewModel` 通过构造参数注入 UseCase，便于测试替换；返回 UI 数据通过 `BackPressUiAction` data class 反馈给 View
- file_role: viewmodel-bootstrap
- boundary: app-core MVVM 边界
- confidence: high
- occurrences: 1
- evidence_kind: positive-example
- sanitized: true
- 路径模式: `app-core/src/main/**/main/mvvm/MainTabViewModel.kt`

```kotlin
class MainTabViewModel(
    private val buildMainTabsUseCase: BuildMainTabsUseCase = BuildMainTabsUseCase(),
    private val handleBackPressUseCase: HandleBackPressUseCase = HandleBackPressUseCase(),
) : ViewModel() {
    fun onBackPressed(nowTimeMs: Long): BackPressUiAction {
        val result = handleBackPressUseCase(lastBackPressTimeMs, nowTimeMs)
        lastBackPressTimeMs = result.nextLastBackPressTimeMs
        return BackPressUiAction(result.shouldExit, result.showHint)
    }
}
```
