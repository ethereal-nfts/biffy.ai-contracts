const { accounts, contract } = require("@openzeppelin/test-environment")
const { time, BN, expectRevert } = require("@openzeppelin/test-helpers")
const {expect} = require("chai")
const config = require("../config")
const ethereal    = accounts[0] //admin

const LoveCycle = contract.fromArtifact("LoveCycle")

const SECONDS_PER_DAY = 86400
const daysCount = 10

describe("LoveCycle",function() {
  before(async function () {
    await time.advanceBlock()
    let latest = await time.latest()
    this.startTime = (30-daysCount)*SECONDS_PER_DAY + latest.toNumber()
    this.loveCycle = await LoveCycle.new()
    await this.loveCycle.initialize(this.startTime)
  })
  describe("State: Cycle 0",function() {
    it("should exist",function() {
      expect(this.loveCycle).to.be.instanceof(LoveCycle)
    })
    describe("#CYCLE_LENGTH",function() {
      it("should be 30 days",async function () {
        let cycleLength = (await this.loveCycle.CYCLE_LENGTH()).toNumber()
        expect(cycleLength).to.equal(30*SECONDS_PER_DAY)
      })
    })
    describe("#startTime",function () {
      it("should be "+(new Date(1000*this.startTime)).toUTCString(),async function () {
        let startTime = (await this.loveCycle.startTime()).toNumber()
        expect(startTime).to.equal(this.startTime)
      })
    })
    describe("#hasStarted",function() {
      it("should return false",async function () {
        let hasStarted = await this.loveCycle.hasStarted()
        await expect(hasStarted).to.equal(false)
      })
    })
    describe("#currentCycle",function() {
      it("should be 0",async function () {
        let currentCycle = (await this.loveCycle.currentCycle()).toNumber()
        expect(currentCycle).to.equal(0)
      })
    })
    describe("#daysSinceCycleStart",function() {
      it("should revert",async function() {
        await expectRevert(
          this.loveCycle.daysSinceCycleStart(),
          "Must be in cycle 1 or higher."
        )
      })
    })
  })

  describe("State: Cycle 1",function() {
    before("should increase time",async function () {
      await time.increase(SECONDS_PER_DAY*30) //1 cycle*30 days
      await time.advanceBlock()
    })
    describe("#hasStarted",function() {
      it("should return true",async function () {
        let hasStarted = await this.loveCycle.hasStarted()
        await expect(hasStarted).to.equal(true)
      })
    })
    describe("#currentCycle",function() {
      it("should return 1",async function () {
        let currentCycle = (await this.loveCycle.currentCycle()).toNumber()
        expect(currentCycle).to.equal(1)
      })
    })
    describe("#daysSinceCycleStart",function() {
      it("should return days count of "+daysCount,async function () {
        let daysSinceCycleStart = (await this.loveCycle.daysSinceCycleStart()).toNumber()
        expect(daysSinceCycleStart).to.equal(daysCount)
      })
    })
  })

  describe("State: Cycle 17",function() {
    before(async function () {
      await time.increase(SECONDS_PER_DAY*(16*30)) //16 cycles*30 days
      await time.advanceBlock()
    })
    describe("#hasStarted",function() {
      it("should return true",async function () {
        let hasStarted = await this.loveCycle.hasStarted()
        await expect(hasStarted).to.equal(true)
      })
    })
    describe("#currentCycle",function() {
      it("should return 17",async function () {
        let currentCycle = (await this.loveCycle.currentCycle()).toNumber()
        expect(currentCycle).to.equal(17)
      })
    })
    describe("#daysSinceCycleStart",function() {
      it("should return days count of "+daysCount,async function () {
        let daysSinceCycleStart = (await this.loveCycle.daysSinceCycleStart()).toNumber()
        expect(daysSinceCycleStart).to.equal(daysCount)
      })
    })
  })

})
