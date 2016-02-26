chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'kaputskey', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/kaputskey')(@robot)

  it 'registers a kaputskey server listener', ->
    expect(@robot.respond).to.have.been.calledWith(/kaputskey server (.+)/i)

  it 'registers a kaputskey server listener', ->
    expect(@robot.respond).to.have.been.calledWith(/kaputskey confirm (.+)/i)
