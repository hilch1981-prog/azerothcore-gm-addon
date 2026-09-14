# 개발 및 배포

대상: WoW 3.3.5a (12340) · Interface 30300 · Lua 5.1.

1. Python 3.12 이상을 준비합니다.
2. `python -m pip install lupa==2.8`로 Lua 5.1 검사 환경을 설치합니다.
3. `python scripts/validate.py`로 파일·구문·로드 검사를 실행합니다.
4. `python scripts/package.py`로 `dist/GMminibar_AzerothCore_3.3.5a_v1.0.0.zip`를 만듭니다.

소스를 수정했다면 `python scripts/manifest.py`로 파일 목록을 갱신한 뒤 다시 검사합니다. ZIP에는 GMminibar 폴더 하나만 들어갑니다. 파일 순서·시간·압축 옵션을 고정하여 같은 소스로 같은 환경에서 다시 만들 수 있습니다.

게임 동작을 바꾸면 실제 대상 클라이언트에서 확인한 결과를 별도로 남깁니다. 비밀번호·접속 정보·SavedVariables·개인 PC 경로·서버 및 클라이언트 바이너리를 커밋하지 않습니다. 기존 저작권·라이선스 고지를 유지합니다.
