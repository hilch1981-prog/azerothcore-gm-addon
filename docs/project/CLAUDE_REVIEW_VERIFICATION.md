# Claude Review Verification

이 문서는 ChatGPT/Codex + Claude 협업 규칙의 실제 적용 여부를 확인하기 위한 비런타임 검증 파일이다.

검증 목표:
- 이 PR의 base 브랜치에 있는 `CLAUDE.md`를 Claude Code Action이 신뢰 지침으로 사용한다.
- Claude 자동 리뷰는 읽기 전용으로 동작한다.
- WotLK 3.3.5a Build 12340 + AzerothCore, Lua 5.1, Interface 30300, Retail API 금지, 기존 UI/UX 보존, 게임 테스트 표현 규칙이 리뷰 기준으로 유지된다.
- 이 파일은 애드온 런타임과 TOC에 영향을 주지 않는다.

이 검증이 성공해도 게임 내 기능 검증을 의미하지 않는다.
