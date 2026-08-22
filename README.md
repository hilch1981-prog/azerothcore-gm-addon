# AzerothAdmin GM Addon 3.2.8-335a

WoW WotLK 3.3.5a Build 12340과 AzerothCore용 한국어 GM 관리 애드온입니다.

## 설치

저장소의 `AzerothAdmin` 폴더를 WoW 클라이언트의 `Interface/AddOns/` 아래에 배치합니다. 최종 경로는 다음과 같아야 합니다.

```text
Interface/AddOns/AzerothAdmin/AzerothAdmin.toc
```

게임 접속 후 `/aa` 명령으로 메인 창을 엽니다.

## 개발 인수인계

Claude Code 또는 다른 개발 도구로 작업하기 전에 다음 문서를 확인하세요.

- `CLAUDE.md`: 핵심 작업 지침
- `PROJECT_STATUS.md`: 기준 소스와 현재 상태
- `TASKS.md`: 기능별 작업 목록
- `DEVELOPMENT_RULES.md`: 호환성 및 검증 규칙
- `REFERENCES.md`: 공개 참고 자료
- `CLAUDE_FIRST_PROMPT.txt`: Claude Code 첫 요청문
- `AGENTS.md`: ChatGPT/Codex 작업 지침
- `CONTRIBUTING.md`: 공동 브랜치·PR 규칙
- `COLLABORATION.md`: ChatGPT/Codex + Claude 연결 방법

## 호환성 원칙

- WoW WotLK 3.3.5a Build 12340
- AzerothCore WotLK
- Lua 5.1
- Retail 전용 API 사용 금지
- 기존 파일과 기능을 보존하는 작은 변경 우선

게임 내 세부 명령과 변경 이력은 `AzerothAdmin/README_KR.txt` 및 패치 노트를 참고하세요.

## 라이선스

애드온 소스의 라이선스는 `AzerothAdmin/LICENSE`를 따릅니다. 외부 라이브러리는 각 구성요소의 라이선스 조건을 확인하세요.
