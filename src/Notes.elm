module Notes exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Markdown
import LocalStorage

type alias Model =
    {
        notes: List LocalStorage.Note,
        newNote: String
    }

type Msg = StartEditing Int | EndEditing Int | UpdateNewNote String | CreateNote | DeleteNote Int | UpdateNote Int String | LoadNotes (List LocalStorage.Note)

initModel : Model
initModel =
    {
        notes = [],
        newNote = ""
    }

initCmd : Cmd Msg
initCmd = LocalStorage.loadNotes ()

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    UpdateNewNote str -> ({ model | newNote = str}, Cmd.none)
    CreateNote -> let newNote = { id = findNextId model, currentlyEditing = False, content = model.newNote }
                      (newModel, cmd) = updateNotes (\x -> newNote :: x) model
                  in ({ newModel | newNote = ""}, cmd)
    DeleteNote delId -> updateNotes (List.filter (\x -> x.id /= delId)) model
    StartEditing id -> updateNotes (List.map (tryChangeEditingStatus id True)) model
    EndEditing id -> updateNotes (List.map (tryChangeEditingStatus id False)) model
    UpdateNote id str -> updateNotes (List.map (tryChangeContent id str)) model
    LoadNotes newNotes -> ({ model | notes = newNotes}, Cmd.none)

updateNotes : (List LocalStorage.Note -> List LocalStorage.Note) -> Model -> (Model, Cmd Msg)
updateNotes func model = let newNotes = func model.notes in ({ model | notes = newNotes}, LocalStorage.saveNotes newNotes)

findNextId : Model -> Int
findNextId model = Maybe.withDefault 0 (List.maximum (List.map .id model.notes)) + 1

tryChangeEditingStatus : Int -> Bool -> LocalStorage.Note -> LocalStorage.Note
tryChangeEditingStatus id status note = if note.id == id then {note | currentlyEditing = status} else note

tryChangeContent : Int -> String -> LocalStorage.Note -> LocalStorage.Note
tryChangeContent id str note = if note.id == id then {note | content = str} else note

view : Model -> List (Html Msg)
view { newNote, notes } = div [class "dashboard-item note"] [textarea [onInput UpdateNewNote, value newNote] [], button [onClick CreateNote] [text "Save Note"]] :: List.map viewNote notes

viewNote : LocalStorage.Note -> Html Msg
viewNote { id, currentlyEditing, content} = div [class "dashboard-item note"] (
      if currentlyEditing
      then [textarea [onInput (UpdateNote id), value content] [], button [class "done", onClick (EndEditing id)] [text "Save Note"]]
      else [div [class "edit", onClick (StartEditing id)] [], div [class "remove", onClick (DeleteNote id)] [], Markdown.toHtml [] content])

subscriptions : Sub Msg
subscriptions = LocalStorage.loadedNotes LoadNotes
