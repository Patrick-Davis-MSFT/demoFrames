import {About, heartbeat } from './models';

export async function getAbout(): Promise<About> {
    const response = await fetch('/about');
    return await response.json();
}

export async function getFuncHeartbeat(): Promise<heartbeat> {
    const response = await fetch('/heartbeatwebapp');
    return await response.json();
}