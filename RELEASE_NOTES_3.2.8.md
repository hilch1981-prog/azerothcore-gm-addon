# AzerothAdmin 3.2.8-335a 변경 내역

## 주요 변경

- AzerothCore 공식 명령 메타데이터 감사와 티켓·그룹 명령 메뉴를 보강했다.
- 공식 WotLK 데이터 기반 네 대륙 퀘스트 보상과 고정/선택 보상을 통합했다.
- 아이템 강화, 낚시, 요리, 응급치료 전문기술 분류를 복구·보강했다.
- InvenCraftInfo를 단일 관리 프레임으로 재구성하고 재열기 임시 상태를 초기화한다.
- 원격 은행은 `.character check bank`가 연 실제 서버 은행 세션만 사용한다.
- 사망·유령 상태 자기 부활과 Questie 아이템 드랍처 순환을 안정화했다.
- 주요 확인 팝업을 관리 창보다 위에 표시하고 공유 StaticPopup 레이어를 복원한다.
- Lua 5.1, TOC 경로·로드 순서, XML 구문, Retail API, 핵심 기능 경계를 CI에서 검사한다.

## 알려진 제한

- Questie 드랍처 이동은 Questie가 설치되어 공개 `QueryItem` 데이터를 제공할 때 가장 정확하다. 데이터가 없으면 퀘스트 POI로 대체한다.
- 원격 은행은 AzerothCore의 `.character check bank` 구현과 해당 GM 권한이 필요하다.
- 아이템 이름·아이콘·요구 레벨은 3.3.5a 클라이언트 캐시가 채워진 뒤 갱신될 수 있다.
- 정적 검사는 실제 서버 권한, DB 내용, 클라이언트 UI 배율 및 다른 애드온과의 충돌을 완전히 재현하지 못한다.
- `GAME_TEST_MATRIX.md`에서 `대기`로 표시된 기능은 실제 3.3.5a 게임 회귀 확인이 필요하다.

## 설치 및 되돌리기

1. 기존 `Interface/AddOns/AzerothAdmin`과 관련 SavedVariables를 백업한다.
2. ZIP 안의 `AzerothAdmin` 폴더를 `Interface/AddOns/`에 복사한다.
3. 문제가 있으면 새 폴더를 제거하고 백업한 폴더와 SavedVariables를 복원한다.
