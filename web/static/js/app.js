// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

var elmDiv = document.getElementById('elm-main')
  , elmApp = Elm.embed(
    Elm.SeatSaver,
    elmDiv,
    {
      seatLists: [],
      serverSeatUpdates: { seatNo: -1, occupied: false }
    }
  )

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("seats:planner", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

channel.on('set_seats', data => {
  console.log('got seats', data.seats)
  elmApp.ports.seatLists.send(data.seats)
  console.log("sent seats data to port ....")
})

channel.on('seat:updated', seat => {
  console.log('Got seat:updated from the server : ', seat)
  elmApp.ports.serverSeatUpdates.send(seat)
  //console.log('after sending to serverSeatUpdates port, message ->', seat)
})

// Get the feed of seat updates from the elm app and send it
// to the backend over channel
elmApp.ports.seatUpdates.subscribe(seat => {
  channel.push("seat:updated", seat)
  console.log('seat:updated from elm app ->', seat)
})
