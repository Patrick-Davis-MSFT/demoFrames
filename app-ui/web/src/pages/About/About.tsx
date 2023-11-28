import { useState, useEffect } from 'react';
import { About } from "../../api/models";
import { getAbout } from '../../api';


export default function blankPage() {
    const [data, setData] = useState<About>();
    useEffect(() => {
        if (!data) {
           async function fetchData() {
                const res = await getAbout();
                setData(res);
            }
            fetchData();
        }
    }
    );

    return (
        <div>
            <h1>About this Demonstration:</h1>
            <table>
            <tr><td>Name:</td><td>{data?.appName}</td></tr>
            <tr><td>Version:</td><td>{data?.appVersion}</td></tr>
            <tr><td>Last Deployed:   </td><td>{data?.deploy_datetime}</td></tr>
            </table>
        </div>
    )
}   