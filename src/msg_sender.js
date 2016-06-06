'use strict'

import node_rest_client from 'node-rest-client'

const args = process.argv.slice(2)
let user_id
if (args.length === 1) user_id = args[0]
user_id = user_id || 'pink'

const publisher_url = 'http://localhost:7070/v1/'
const rest_client = new node_rest_client.Client()

const postOpts = {
  data: {
    user_id: user_id,
    message: "hello there",
    blob: {
      someLink: "xxxxxyyyyy"
    }
  },
  headers: {
    "Content-Type": "application/json"
  }
}

function sendMessage() {
  rest_client.post(publisher_url + 'systems', postOpts, (data) => {
    console.log(`sending status: ${data.status}`)
  })
}

process.on('uncaughtException', (err) => {
  console.log('unhandled exception occurred: ', err)
})

sendMessage()
