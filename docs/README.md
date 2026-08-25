# 저장소 문서 구조

이 디렉터리는 런타임 소스와 개발·배포 기록을 분리하기 위한 문서 전용 영역입니다.

- `history/changelog/`: 과거 버전 CHANGELOG
- `history/patch-notes/`: 과거 패치 노트
- `history/test-reports/`: 과거 수동/배포 테스트 기록
- `audits/`: 명령·데이터 감사 결과
- `releases/`: 릴리스 노트
- `project/`: 구조도, 기능 맵, 테스트 매트릭스, 참고자료, 작업 인계 문서

`AzerothAdmin/` 폴더에는 실제 애드온 실행에 필요한 Lua/TOC/리소스와 배포에 필요한 최소 고지 문서만 유지합니다.

새 로그성 산출물은 저장소 루트나 `AzerothAdmin/`에 직접 추가하지 않습니다. 임시 실행 로그는 Git에 커밋하지 않고, 유지 가치가 있는 검증 결과만 이 문서 구조에 정리합니다.
