import * as react from 'react'

import { ApplicationInsights } from '@microsoft/applicationinsights-web';
import { ReactPlugin, withAITracking } from '@microsoft/applicationinsights-react-js';
import { createBrowserHistory } from "history";

import { HashRouter, Routes, Route } from "react-router-dom";
import { initializeIcons } from "@fluentui/react";


import './App.css'
import Layout from './layout/Layout'
import BlankPage from './pages/BlankPage';
import About from './pages/About/About';
import NoPage from './pages/NoPage';

const AppInsight_CS = import.meta.env.VITE_APPLICATIONINSIGHTS_CONNECTION_STRING

const browserHistory = createBrowserHistory();
const reactPlugin = new ReactPlugin();
const appInsights = new ApplicationInsights({
  config: {
    connectionString: AppInsight_CS,
    extensions: [reactPlugin],
    extensionConfig: {
      [reactPlugin.identifier]: { history: browserHistory }
    }
  }
});

if(AppInsight_CS){
  appInsights.loadAppInsights();
}
initializeIcons();

function App() {

  return (
    <HashRouter>
    <Routes>
        <Route path="/" element={<Layout />}>
            <Route index element={<BlankPage />} />
            <Route path="/about" element={<About />} />
            <Route path="*" element={<NoPage />} />
        </Route>
    </Routes>
</HashRouter>
  )
}



export default (AppInsight_CS !== undefined) ? withAITracking(reactPlugin, App) : App;
 