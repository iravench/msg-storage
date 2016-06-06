'use strict'

import { expect } from 'chai'
import Primus from 'primus'
import Mirage from 'mirage'
import Emitter from 'primus-emitter'
import node_rest_client from 'node-rest-client'

const broker_url = 'http://localhost:8080/v1/tickets'
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
const rest_client = new node_rest_client.Client()
const any_manager_url = 'http://localhost:9090'
const Socket = Primus.createSocket({
  transformer: 'engine.io',
  parser: 'JSON',
  plugin: {
    'mirage': Mirage,
    'emitter': Emitter
  }
})

describe('client login to any manager', () => {
  describe('with invalid token', () => {
    let invalid_token = 'some invalid token'
    let client = new Socket(any_manager_url, {
      mirage: invalid_token,
      manual: true,
      strategy: [ 'online', 'timeout', 'disconnect' ] })

    afterEach(() => {
      setTimeout(() => { client.destroy() }, 1000)
    })

    it('state connection as unauthorized', (done) => {
      client.on('mkm::unauthorized', (err) => {
        done()
      })

      client.open()
    })
  })
})

describe('client login to assigned manager', () => {
  let client

  afterEach(() => {
    if (client) {
      setTimeout(() => { client.destroy() }, 1000)
    }
  })

  it('state connection as authorized', (done) => {
    rest_client.post(broker_url, postOpts, (data) => {
      client = new Socket('http://' + data.fm_ip + ':' + data.fm_port, {
        mirage: data.token,
        manual: true,
        strategy: [ 'online', 'timeout', 'disconnect' ] })
      client.on('mkm::authorized', () => {
        done()
      })
      client.open()
    })
  })
})

describe('client attempts to acquire ticket', () => {
  describe('without user_id or device_id', () => {
    it('receive validation error', (done) => {
      rest_client.post(broker_url, { headers: { "Content-Type": "application/json" } }, (data) => {
        expect(data.status).to.exist
        expect(data.status.code).to.equal(400)
        expect(data.status.message).to.have.string('bad user')
        done()
      })
    })
  })

  describe('with user_id or device_id', () => {
    it('receive both front machine conn info and token', (done) => {
      rest_client.post(broker_url, postOpts, (data) => {
        expect(data.fm_ip).to.exist
        expect(data.fm_port).to.exist
        expect(data.token).to.exist
        done()
      })
    })
  })
})
