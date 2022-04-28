

const MESSAGE_TYPE = {
    MSG_DEBUG: 0x0,
    MSG_FPGA_0: 0x1,
    MSG_FPGA_1: 0x2,
    MSG_SYNC: 0xFF,
};

let baudRate = 115200;

let outputStream;
let inputStream;
let port;

// EventListeners

let sendText = document.querySelector("#sendText");
var receiveText = document.querySelector("#receiveText");
var logText = document.querySelector("#log");
let statusBar = document.querySelector("#statusBar");

sendText.addEventListener('keydown', (e) => {
    if (e.code == "Enter") {
        processCommand();
    }
});


navigator.serial.addEventListener('connect', e => {
    statusBar.innerText = `Connected to ${e.port}`;
});

navigator.serial.addEventListener('disconnect', e => {
    statusBar.innerText = `Disconnected`;
});


async function processCommand() {
    let msg = sendText.value;
    addToTerminal(msg, type = 'command')
    if (outputStream) {
        if (msg == 'disconnect') {
            serialDisconnect();
        } else if (msg == 'clear') {
            logText.innerHTML = '';
            addToTerminal("OK", "debug")
        } else {
            writeToStream(msg)
        }
    } else {
        if (msg == 'connect') {
            await serialConnect();
        } else {
            addToTerminal("Unknown command. Connect to a serial device first.", "debug");
        }
    }

    sendText.value = "";
}

async function serialConnect() {
    // Try Serial Connect
    try {
        port = await navigator.serial.requestPort({
            filters: [{
                usbVendorId: 0x10C4 // SiliconLabs
            }]
        });

        await port.open({
            baudRate: baudRate
        });

        statusBar.innerText = "Connected";

        addToTerminal("Successfully connected to Serial device", "debug")

        inputDone = port.readable;
        reader = port.readable.getReader();

        const encoder = new TextEncoderStream();
        outputDone = encoder.readable.pipeTo(port.writable);
        outputStream = encoder.writable;

        readLoop();
    } catch (e) {
        statusBar.innerText = e;
    }
}

// Write to the Serial port
async function writeToStream(line) {
    const writer = outputStream.getWriter();
    writer.write(line + "\n");
    writer.releaseLock();
}

// Disconnect from the Serial port
async function serialDisconnect() {

    if (reader) {
        await reader.cancel();
        await inputDone.catch(() => { });
        reader = null;
        inputDone = null;
    }
    if (outputStream) {
        await outputStream.getWriter().close();
        await outputDone;
        outputStream = null;
        outputDone = null;
    }
    statusBar.innerText = "Disconnected";
    //Close the port.
    await port.close();
    port = null;
}



var synced;

//Read the incoming data
async function readLoop() {
    let currentMessageType = null;
    let currentDataBuffer = [];
    synced = false;

    // sync
    setTimeout(() => {
        writeToStream("moin");
    }, 500);

    while (true) {
        const { value, done } = await reader.read();
        if (done === true) {
            break;
        }

        // console.log(value);

        value.forEach((byte) => {
            if (synced) {
                switch (currentMessageType) {
                    case null:
                        currentMessageType = byte;
                        currentDataBuffer = [];
                        break;

                    case MESSAGE_TYPE.MSG_DEBUG:
                        if (byte === 10) { // 10 is \n
                            handleMsgDebug(currentDataBuffer);
                            currentMessageType = null;
                        } else {
                            currentDataBuffer.push(byte);
                        }
                        break;

                    case MESSAGE_TYPE.MSG_FPGA_0:
                    case MESSAGE_TYPE.MSG_FPGA_1:
                        currentDataBuffer.push(byte);
                        if (currentDataBuffer.length === 4) {
                            handleMsgFPGA(currentMessageType, currentDataBuffer);
                            currentMessageType = null;
                        }
                        break;
                    case MESSAGE_TYPE.MSG_SYNC: // not needed unless user invokes command "moin"
                        currentDataBuffer = [MESSAGE_TYPE.MSG_SYNC, byte]; // twice because setting currentMessageType takes one
                        synced = false;
                        break;
                    default:
                        throw "Unknown Message Type Byte: " + currentMessageType.toString(2).padStart(8, '0');
                }
            } else {
                if (currentDataBuffer.length >= 5 && byte === 0) {
                    synced = true;
                    currentMessageType = null;
                }

                if (byte === 0xFF) {
                    currentDataBuffer.push(byte);
                } else {
                    currentDataBuffer = [];
                }
            }
        });
    }
}

function handleMsgDebug(data) {
    const decoder = new TextDecoder();
    const text = decoder.decode(new Uint8Array(data));
    addToTerminal(text);
}

var gpio = {};
let lastPC = 0;

function handleMsgFPGA(messageType, data) {
    gpio[messageType] = data;
    if (gpio[1] && gpio[2]) {
        let pc = ((Uint8ArrayToUint32(gpio[2]) >> 8) & 0xFF);

        if(pc == 0 && lastPC > 0){
            addToTerminal("LOOP detected", "debug");
        }

        lastPC = pc;

        let pcString = "0x" + pc.toString(16).padStart(4, '0').toUpperCase();
        let swb = (Uint8ArrayToUint32(gpio[2])) & 0x1;
        let addr = "0x" + ((Uint8ArrayToUint32(gpio[2]) >> 24) & 0xF).toString(16).padStart(2, '0').toUpperCase();
        let dat = "0x" + Uint8ArrayToUint32(gpio[1]).toString(16).padStart(8, '0').toUpperCase();
        addToLog(pcString + (swb ? (` - ${addr}: ${dat}`) : " "));
        gpio = {}
    }
}

function Uint8ArrayToUint32(data) {
    return data.reduce((pre, curr, i) => pre | (curr << ((data.length - 1 - i) * 8)), 0) >>> 0;
}

function addToTerminal(str, type = 'reply') {
    receiveText.insertAdjacentHTML("beforeend", `<span class="${type}">${str}</span>`);
    receiveText.parentElement.scrollTop = receiveText.parentElement.scrollHeight;
}

function addToLog(str) {
    logText.insertAdjacentHTML("beforeend", `<span class="log">${str}</span>`);
    logText.parentElement.scrollTop = logText.parentElement.scrollHeight;
}