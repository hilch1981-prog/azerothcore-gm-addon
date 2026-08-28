# 최종 정적 검증 후보 기록

대상: WoW WotLK 3.3.5a Build 12340 + AzerothCore용 AzerothAdmin GM 애드온

이 문서는 현재 누적 개발 스택을 `main` 기준 하나의 최종 후보 PR에서 다시 검증하기 위한 기록이다.

## 자동 검증 범위

- Lua 5.1 문법
- Interface 30300 / WotLK 3.3.5a API 호환성
- Retail 전용 API 금지
- TOC 파일 존재 여부와 로드 순서
- XML/애드온 구조 검사
- AzerothCore GM 명령 메타데이터/권한 관련 회귀 검사
- 모듈 구조 및 런타임 다국어 로컬라이징 회귀 검사
- koKR 검색/파싱/분류 데이터와 사용자 표시 문자열 경계
- 배포 ZIP 구조와 무결성
- 외부 참고 소스 출처/라이선스 표기
- Claude Code Review 독립 검토

## Claude 협업 방식

1. ChatGPT/Codex가 실제 소스와 테스트를 먼저 검토한다.
2. GitHub Actions의 Claude Code Review가 PR 전체 diff를 독립적으로 검토한다.
3. Claude의 지적은 ChatGPT/Codex가 실제 Lua/XML/TOC/AzerothCore 근거와 대조한다.
4. 유효한 지적만 수정하고 CI와 Claude 리뷰를 다시 수행한다.
5. 미해결 리뷰 스레드가 없어야 정적 검증 후보로 인정한다.

## 중요 제한

정적 검사와 Claude 리뷰 성공은 실제 WoW 클라이언트 게임 테스트를 대체하지 않는다.

특히 크리처 목록 선택 후 마우스 카메라 회귀, 레이드/던전 순간이동, 한글 IME 포커스 해제, QuestHelper, 은행, 자기 부활, 아이템/전문기술 창, 다국어 레이아웃 및 팝업/툴팁 동작은 `docs/project/GAME_TEST_MATRIX.md`에 따라 실제 게임에서 검증해야 한다. 동작하지 않은 크리처 3D 미리보기는 사용자 게임 테스트 결과에 따라 제거했다.

따라서 게임 내 검증 전에는 이 후보를 `게임 테스트 완료`, `최종 배포 완료`라고 표현하지 않는다.
