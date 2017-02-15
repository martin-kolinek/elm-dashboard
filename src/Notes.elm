module Notes exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Markdown

type alias Model =
    {
        notes: List Note,
        newNote: String
    }

type alias Note =
    {
        id: Int,
        currentlyEditing: Bool,
        content: String
    }

type Msg = StartEditing Int | EndEditing Int | UpdateNewNote String | CreateNote | DeleteNote Int | UpdateNote Int String

initModel : Model
initModel =
    {
        notes = [],
        newNote = ""
    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    UpdateNewNote str -> ({ model | newNote = str}, Cmd.none)
    CreateNote -> let newNote = { id = findNextId model, currentlyEditing = False, content = model.newNote } in ({ model | notes = newNote :: model.notes, newNote = ""}, Cmd.none)
    DeleteNote delId -> ({ model | notes = List.filter (\x -> x.id /= delId) model.notes}, Cmd.none)
    StartEditing id -> ({ model | notes = List.map (tryChangeEditingStatus id True) model.notes}, Cmd.none)
    EndEditing id -> ({ model | notes = List.map (tryChangeEditingStatus id False) model.notes}, Cmd.none)
    UpdateNote id str -> ({ model | notes = List.map (tryChangeContent id str) model.notes}, Cmd.none)

findNextId : Model -> Int
findNextId model = Maybe.withDefault 0 (List.maximum (List.map .id model.notes)) + 1

tryChangeEditingStatus : Int -> Bool -> Note -> Note
tryChangeEditingStatus id status note = if note.id == id then {note | currentlyEditing = status} else note

tryChangeContent : Int -> String -> Note -> Note
tryChangeContent id str note = if note.id == id then {note | content = str} else note

view : Model -> List (Html Msg)
view { newNote, notes } = div [class "dashboard-item"] [textarea [onInput UpdateNewNote, value newNote] [], button [onClick CreateNote] [text "done"]] :: List.map viewNote notes

viewNote : Note -> Html Msg
viewNote { id, currentlyEditing, content} = div [class "dashboard-item"] (
      if currentlyEditing
      then [textarea [onInput (UpdateNote id), value content] [], button [onClick (EndEditing id)] [text "done"]]
      else [Markdown.toHtml [] content, button [onClick (StartEditing id)] [text "edit"], button [onClick (DeleteNote id)] [text "delete"]])
