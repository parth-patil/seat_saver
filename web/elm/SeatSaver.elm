module SeatSaver (..) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import StartApp
import Effects exposing (Effects, Never)
import Task exposing (Task)
import Http
import Json.Decode as Json exposing ((:=))
import Debug exposing (log)

-- MODEL


type alias Seat =
  { seatNo : Int
  , occupied : Bool
  }


type alias Model =
  { seats : List Seat -- change this to use Map
  , lastUpdatedSeat : Maybe Seat
  }


emptyModel : Model
emptyModel =
  { seats = [], lastUpdatedSeat = Nothing }


init : ( Model, Effects Action )
init =
  ( emptyModel, Effects.none )



-- UPDATE


type Action
  = Toggle Seat
  | SetSeats (List Seat)
  | SeatUpdate Seat


update : Action -> Model -> ( Model, Effects Action )
update action model =
  case action of
    Toggle seatToToggle ->
      let
        seatAfterToggle =
          { seatToToggle | occupied = not seatToToggle.occupied }

        doUpdate seat =
          if seat.seatNo == seatToToggle.seatNo then
            seatAfterToggle
          else
            seat

        newModel =
          { model
          | seats = List.map doUpdate model.seats
          , lastUpdatedSeat = Just seatAfterToggle
          }
      in
        ( newModel, Effects.none )

    SetSeats seats ->
      let
        _ = Debug.log "SeatSeats was called ...."
      in
        ( { model | seats = seats }, Effects.none )

    SeatUpdate seat ->
      let
        _ = Debug.log "SeatUpdate was called ...."
      in
        --( model, Effects.none )
        ( { model | seats = (updateSeat model.seats seat) }, Effects.none )




updateSeat : List Seat -> Seat -> List Seat
updateSeat seats seatToUpdate =
  let
    replaceIfMatch seat =
      if seat.seatNo == seatToUpdate.seatNo then
        seatToUpdate
      else
        seat
  in
    List.map replaceIfMatch seats


-- EFFECTS

{--
fetchSeats : Effects Action
fetchSeats =
  Http.get decodeSeats "http://localhost:4000/api/seats"
    |> Task.toMaybe
    |> Task.map SetSeats
    |> Effects.task
--}

decodeSeats : Json.Decoder (List Seat)
decodeSeats =
  let
    seat =
      Json.object2
        (\seatNo occupied -> (Seat seatNo occupied))
        ("seatNo" := Json.int)
        ("occupied" := Json.bool)
  in
    Json.at [ "data" ] (Json.list seat)



-- SIGNALS

-- incoming ports
port seatLists : Signal (List Seat)

incomingActions : Signal Action
incomingActions =
  Signal.map SetSeats seatLists


port serverSeatUpdates : Signal Seat

seatUpdateActions : Signal Action
seatUpdateActions =
  serverSeatUpdates
    |> Signal.map SeatUpdate


-- outgoing port
port seatUpdates : Signal Seat
port seatUpdates =
  let
    defaultSeat : Seat
    defaultSeat =
      { seatNo = -1, occupied = False }
  in
    app.model
      |> Signal.filterMap (\m -> m.lastUpdatedSeat) defaultSeat
      |> Signal.dropRepeats


-- VIEW


view : Signal.Address Action -> Model -> Html
view address model =
  ul [ class "seats" ] (List.map (seatItem address) model.seats)


seatItem : Signal.Address Action -> Seat -> Html
seatItem address seat =
  let
    occupiedClass =
      if seat.occupied then
        "occupied"
      else
        "available"
  in
    li
      [ class ("seat " ++ occupiedClass)
      , onClick address (Toggle seat)
      ]
      [ text (toString seat.seatNo) ]


app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = [ incomingActions, seatUpdateActions ]
    }


main : Signal Html
main =
  app.html


port tasks : Signal (Task Never ())
port tasks =
  app.tasks
