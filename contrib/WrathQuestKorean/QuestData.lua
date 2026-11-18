local _, addon = ...

-- These are short Korean summaries written for the preview.
-- enTitle is both the English match and a guard against reused quest IDs.
addon.quests = {
    [783] = {
        enTitle = "A Threat Within",
        title = "내부의 위협",
        description = "스톰윈드 경비병 상당수가 외지로 떠난 사이, 북녘골에 남은 경비병들이 일손을 구하고 있습니다. 지원하려면 윌렘 뒤편 수도원으로 들어가세요.",
        objectives = "수도원 안에 있는 치안대장 맥브라이드와 대화하세요.",
        completion = "맥브라이드가 지원을 환영합니다. 외부의 적에 대응하는 동안 왕국 안의 치안도 지켜야 합니다.",
    },
    [7] = {
        enTitle = "Kobold Camp Cleanup",
        title = "코볼트 야영지 소탕",
        description = "수도원 북쪽 숲에 코볼트가 모여들었습니다. 맥브라이드가 북녘골의 안전을 위해 이들을 소탕해 달라고 부탁합니다.",
        objectives = "코볼트 졸개 10마리를 처치한 뒤 치안대장 맥브라이드에게 돌아가세요.",
        progress = "북쪽 숲에서 코볼트 졸개 10마리를 처치해야 합니다.",
        completion = "맥브라이드에게 코볼트 소탕 결과를 보고했습니다.",
    },
    [15] = {
        enTitle = "Investigate Echo Ridge",
        title = "메아리 산마루 조사",
        description = "북쪽 메아리 산마루 광산 부근에 코볼트 일꾼들이 모였습니다. 광산 주변을 조사하고 위협을 줄이세요.",
        objectives = "코볼트 일꾼 10마리를 처치한 뒤 치안대장 맥브라이드에게 돌아가세요.",
        progress = "메아리 산마루 광산 근처에서 코볼트 일꾼을 찾으세요.",
        completion = "맥브라이드에게 메아리 산마루 광산 부근의 조사 결과를 보고했습니다.",
    },
}
