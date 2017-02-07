import Html exposing (..)
import Html.Attributes exposing (..)

main : Program Never Model Msg
main = beginnerProgram { model = model, view = view, update = update }

type alias Model = ()

model : Model
model = ()

type Msg = Unused

update : Msg -> Model -> Model
update _ model = model

view : Model -> Html Msg
view model = div [class "content"] [text "Hello world"]
