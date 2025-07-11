// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Outlet, NavLink } from "react-router-dom";


// import openai from "../assets/openai.svg";
import aiIcon from "../assets/02749-icon-service-Azure-Applied-AI-Services.svg";
import aiFoundryIcon from "../assets/03513-icon-service-AI-Studio.svg";
import styles from "./Layout.module.css";
import msft from "../assets/MS-Azure_logo_stacked_c-white_rgb.png";
import { Add28Filled } from "@fluentui/react-icons";

const Layout = () => {
    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <div className={styles.headerContainer}>
                    <div className={styles.headerTitleContainer}>
                        <img src={aiFoundryIcon} alt="Azure AI Foundry" className={styles.headerLogo} />
                        <Add28Filled />
                        <img src={aiIcon} alt="Azure AI Services" className={styles.headerLogoMiddle} />
                        <Add28Filled />
                        <img src={msft} alt="Azure Cloud" className={styles.headerLogoMsft} />
                        <h3 className={styles.headerTitle}>HEADER HERE</h3>
                    </div>
                    <nav>
                        <ul className={styles.headerNavList}>
                            <li>
                                <NavLink to="/" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                    First Link
                                </NavLink>
                            </li>
                            <li className={styles.headerNavLeftMargin}>
                                <NavLink to="/second" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                Second Link
                                </NavLink>
                            </li>
                            <li className={styles.headerNavLeftMargin}>
                                <NavLink to="/about" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                About
                                </NavLink>
                            </li>
                        </ul>
                    </nav>
                </div>
            </header>
            <div className={styles.raibanner}>
                <span className={styles.raiwarning}>AI-generated content may be incorrect</span>
            </div>

            <Outlet />

            <footer>
            </footer>
        </div>
    );
};

export default Layout;
