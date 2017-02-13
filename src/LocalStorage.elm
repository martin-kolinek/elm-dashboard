port module LocalStorage exposing (..)

port saveDismissedNews: List Int -> Cmd msg

port loadDismissedNews: () -> Cmd msg

port dismissedNews: (List Int -> msg) -> Sub msg
