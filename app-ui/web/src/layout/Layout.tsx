// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Outlet, NavLink, Link } from "react-router-dom";


import openai from "../assets/openai.svg";
import styles from "./Layout.module.css";
import msft from "../assets/MS-Azure_logo_stacked_c-white_rgb.png";
import { Add28Filled } from "@fluentui/react-icons";

const Layout = () => {
    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <div className={styles.headerContainer}>
                    <div className={styles.headerTitleContainer}>
                        <img src={openai} alt="Azure OpenAI" className={styles.headerLogo} />
                        <Add28Filled />
                        <img src={msft} alt="Azure OpenAI" className={styles.headerLogoMsft} />
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
