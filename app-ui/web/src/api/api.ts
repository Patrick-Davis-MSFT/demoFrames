import {About } from './models';

export async function getAbout(): Promise<About> {
    const response = await fetch('/about');
    return await response.json();
}