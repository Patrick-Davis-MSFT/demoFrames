/* eslint-disable no-inner-declarations */
/* eslint-disable react-hooks/rules-of-hooks */
import { useState, useEffect } from 'react';
import { About, heartbeat } from "../../api/models";
import { getAbout, getFuncHeartbeat } from '../../api';


export default function blankPage() {
    const [data, setData] = useState<About>();
    const [hbWeb, setHbWeb] = useState<heartbeat>();
    useEffect(() => {
        if (!data) {
           async function fetchData() {
                const res = await getAbout();
                setData(res);
            }
            fetchData();
        }
        
        if (!hbWeb) {
            async function fetchHb() {
                const res = await getFuncHeartbeat();
                setHbWeb(res);
            }
            fetchHb();
        }
    }
    );

    return (
        <div>
            <h1>About this Demonstration:</h1>
            <table>
            <tr><td>Name:</td><td>{data?.appName || "Fetching... "}</td></tr>
            <tr><td>Version:</td><td>{data?.appVersion}</td></tr>
            <tr><td>Last Deployed:   </td><td>{data?.deploy_datetime}</td></tr>
            <tr><td>Heartbeat Function API:   </td><td>{hbWeb?.status || "no response"}</td></tr>
            </table>
        </div>
    )
}   