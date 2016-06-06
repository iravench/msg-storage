'use strict'

import node_rest_client from 'node-rest-client'

const publisher_url = 'http://localhost:7070/v1/'
const rest_client = new node_rest_client.Client()

const postOpts = {
  data: {
    message: "hello there",
    blob: {
      someLink: "xxxxxyyyyy"
    }
  },
  headers: {
    "Content-Type": "application/json"
  }
}

function broadCastMessage() {
  rest_client.post(publisher_url + 'systems', postOpts, (data) => {
    console.log(`broadcast status: ${data.status}`)
  })
}

process.on('uncaughtException', (err) => {
  console.log('unhandled exception occurred: ', err)
})

setInterval(broadCastMessage, 3000)
