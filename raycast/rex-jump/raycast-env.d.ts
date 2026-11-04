/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** rex binary - Path to the rex CLI */
  "rexPath": string,
  /** Rex app name - The app to bring forward after jumping */
  "appName": string,
  /** aerospace binary - Path to the AeroSpace CLI (used to raise the Rex window already showing a session) */
  "aerospacePath": string
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `jump` command */
  export type Jump = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `jump` command */
  export type Jump = {}
}

