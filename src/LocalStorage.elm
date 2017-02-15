port module LocalStorage exposing (..)

port saveDismissedNews: List Int -> Cmd msg

port loadDismissedNews: () -> Cmd msg

port dismissedNews: (List Int -> msg) -> Sub msg

type alias Note =
    {
        id: Int,
        currentlyEditing: Bool,
        content: String
    }

port saveNotes: List Note -> Cmd msg
port loadNotes: () -> Cmd msg
port loadedNotes: (List Note -> msg) -> Sub msg
