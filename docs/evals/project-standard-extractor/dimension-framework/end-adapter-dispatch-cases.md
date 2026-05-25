---
name: end-adapter-dispatch-cases
description: 端 adapter dispatch 评估场景：AE17（按 sub_domain 选骨架模板）
type: evals
phase: phase-2
ae: [AE17]
---

# End Adapter Dispatch Cases

## EAD-001 — AE17: 端 adapter dispatch 按 sub_domain 选骨架

**Given**

三个并行输入,验证 dispatch 路由不混淆：

```yaml
inputs:
  - project_path: /mock/kaz-android
    inferred_domain: 01-app-client
    inferred_sub_domain: android
    architecture_tags: [kmp, clean-architecture]

  - project_path: /mock/hk-stock-h5
    inferred_domain: 01-app-client
    inferred_sub_domain: rn-cross-platform
    architecture_tags: [react-native, turbomodule, native-bridge]

  - project_path: /mock/broker-backend
    inferred_domain: 04-backend
    inferred_sub_domain: java-spring
    architecture_tags: [spring-boot, layered]
```

骨架文件池：

```
assets/skeletons/
  app-client/android-skeleton.md          # sub_domain=android
  app-client/kmp-shared-skeleton.md       # sub_domain=kmp-shared
  app-client/rn-cross-platform-skeleton.md # sub_domain=rn-cross-platform（含 TurboModule/NativeBridge 章节）
  backend/java-spring-skeleton.md         # sub_domain=java-spring
  industry/securities-skeleton.md         # domain=09-industry
```

**When**

generation agent（端 adapter 模式）按 `domain + sub_domain` 分发骨架。

**Then**

- `/mock/kaz-android` → 选用 `android-skeleton.md`（含 KMP+Clean 章节,不含 RN/TurboModule）
- `/mock/hk-stock-h5` → 选用 `rn-cross-platform-skeleton.md`（含 TurboModule/NativeBridge/bundle 多入口章节）
- `/mock/broker-backend` → 选用 `java-spring-skeleton.md`（含 Spring 分层规则）
- 不存在 `sub_domain` 对应骨架时:降级选用 `domain` 级通用骨架 + 警告 `SKELETON_FALLBACK_GENERIC`
- 骨架选择结果写入 `project-profile.md#skeleton_selected` 字段
- generation agent **不跨端混用**骨架（android ≠ rn，backend ≠ app-client）

**RN 跨端特殊断言**

```bash
# hk-stock-h5 产物应含 NativeBridge / TurboModule 章节
grep -q "NativeBridge\|TurboModule" standard-rn-cross-platform.md
# android 产物不含 TurboModule 章节
grep -qv "TurboModule" standard-android.md
```

**dispatch 路由断言（profile 字段）**

```bash
jq '.skeleton_selected' project-profile.md | grep -q "rn-cross-platform-skeleton"
jq '.skeleton_selected' project-profile-backend.md | grep -q "java-spring-skeleton"
```
