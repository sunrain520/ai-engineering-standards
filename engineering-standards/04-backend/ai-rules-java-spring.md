# java-spring AI Rules

## Must
- When adding a Java Spring API, keep data access below the service layer and do not call Mapper or Repository from Controller. (standard: backend-java-layering-001)
- When adding API exception handling, prefer centralized ControllerAdvice or ExceptionHandler patterns already present in the service. (standard: backend-java-exception-003)

## Must Not
- Controller must not call Mapper or Repository directly. (standard: backend-java-layering-001)
- Do not scatter unrelated generic exception handling across controllers. (standard: backend-java-exception-003)
