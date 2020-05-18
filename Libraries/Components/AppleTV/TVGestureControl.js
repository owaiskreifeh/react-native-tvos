/**
 * @format
 * @flow
 */

'use strict';

const TVGestureBridge = require('../../BatchedBridge/NativeModules').TVGestureBridge;

module.exports = {
    addGestureRecognizers: () => {
        TVGestureBridge && TVGestureBridge.reinitializeTVRemote(1);
    },
    removeGestureRecognizers: () => {
        TVGestureBridge && TVGestureBridge.reinitializeTVRemote(0);
    }
};
