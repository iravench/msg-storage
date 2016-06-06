'use strict'

import Primus from 'primus'
import Mirage from 'mirage'
import Emitter from 'primus-emitter'
import node_rest_client from 'node-rest-client'

const args = process.argv.slice(2)
let tmpStep = 10, tmpTargetTotal = 250
if (args.length === 2) {
  tmpStep = parseInt(args[0], 10)
  tmpTargetTotal = parseInt(args[1], 10)
  if (tmpStep < 0 || tmpTargetTotal < 0 || tmpStep > tmpTargetTotal)
    throw RangeError('Usage: load_generator.js <step> <targetTotal>, both step and targetTotal are integer and step < targetTotal')
}
const step = tmpStep
const targetTotal = tmpTargetTotal
console.log(`generating ${targetTotal} connections with a step of ${step}...`)

const broker_url = 'http://localhost:8080/v1/tickets'
const rest_client = new node_rest_client.Client()
const Socket = Primus.createSocket({
  transformer: 'engine.io',
  parser: 'JSON',
  plugin: {
    'mirage': Mirage,
    'emitter': Emitter
  }
})

function getRandomArbitrary(min, max) {
  return Math.random() * (max - min) + min
}

function getRandomName(prefix) {
  return prefix + '.' + getRandomArbitrary(1, 1000)
}

const postOpts = {
  data: {
    user: {
      user_id: "pink",
      device_id: "test.client"
    }
  },
  headers: {
    "Content-Type": "application/json"
  }
}

function fireUpClients() {
  const strategy = [ 'online', 'timeout', 'disconnect' ]
  for (let i=0; i<step; i++) {
    postOpts.data.user.user_id = getRandomName('pink')
    postOpts.data.user.device_id = getRandomName('device')
    rest_client.post(broker_url, postOpts, (data) => {
      const socketOpts = { mirage: data.token, manual: true, strategy: strategy }
      const socketUrl = 'http://' + data.fm_ip + ':' + data.fm_port
      const client = new Socket(socketUrl, socketOpts)

      client.on('mkm::authorized', () => {
        client.on('mkm::ibc::system', (data) => {
          console.log('category - system:', data)
        })
        client.on('mkm::ibc::comment', (data) => {
          console.log('category - comment:', data)
        })
        client.on('mkm::ibc::favourite', (data) => {
          console.log('category - favourite:', data)
        })
        client.on('mkm::ibc::misc', (data) => {
          console.log('category - misc:', data)
        })
      })
      client.open()
    })
  }
  return step
}

process.on('uncaughtException', (err) => {
  console.log('unhandled exception occurred: ', err)
})

let counter = 0
function timerCallback() {
  counter += fireUpClients()
  console.log('current connection numbers are ', counter)
  if (counter < targetTotal) setTimeout(timerCallback, 1000)
}

timerCallback()
