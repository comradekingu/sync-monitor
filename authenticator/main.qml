import QtQuick 2.9

import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.OnlineAccounts 2.0

MainView {
    id: root

    property bool accountFound: false
    property bool wasAuthenticated: false

    width: units.gu(40)
    height: units.gu(71)

    AccountModel {
        id: accountModel

        serviceId: ONLINE_ACCOUNT.serviceName
        applicationId: "com.ubuntu.calendar_calendar"
        onReadyChanged:  {
            console.debug("Model is Ready:" + ready)
            console.debug("Model count:" + count)
            if (count > 0) {
                root.accountFound = true
                pageStack.push(accountPageComponent, {"account" : accountModel.get(0, "account")})
            }
        }
    }

    PageStack {
        id: pageStack

        Component.onCompleted: {
            if (!root.accountFound) {
                pageStack.push(loadingPageComponent)
                accountNotFoundTimeout.start()
            }
        }
    }

    Timer {
        id: accountNotFoundTimeout

        interval: 5000
        repeat: false
        onTriggered: {
            if (!root.accountFound) {
                pageStack.push(accountNotFoundPageComponent)
            }
        }
    }

    Component {
        id: loadingPageComponent

        Page {
            id: loadingPage

            title: i18n.tr("Accounts")

            ActivityIndicator {
                id: activity

                anchors.centerIn : parent
                running: visible
                visible: loadingPage.active
            }
        }
    }

    Component {
        id: accountNotFoundPageComponent

        Page {
            id: accountNotFoundPage

            title: i18n.tr("Accounts")

            head.backAction: Action {
                iconName: "back"
                text: i18n.tr("Quit")
                onTriggered: Qt.quit()
            }

            Label {
                anchors.centerIn: parent
                text: i18n.tr("Failed to load account information.")
            }
        }
    }

    Component {
        id: accountPageComponent

        Page {
            id: accountPage

            property var account
            property bool loginInProcess: false

            function getServiceIcon(serviceId)
            {
                if (serviceId.indexOf("google") != -1) {
                    return "google"
                } else {
                    return "account"
                }
            }

            function accountAuthenticationReply(authenticationData)
            {
                accountPage.loginInProcess = false
                if (authenticationData.errorCode) {
                    console.warn("Authentication failed: " + authenticationData.errorCode + ": " + authenticationData.errorText)

                } else {
                    accountPage.loginInProcess = false
                    root.wasAuthenticated = true
                    console.debug("Authentication successful.")
                    Qt.quit()
                }
            }


            title: accountPage.loginInProcess ? i18n.tr("Logging in...") : i18n.tr("Sign in to sync")

            head.backAction: Action {
                iconName: "back"
                text: i18n.tr("Quit")
                onTriggered: Qt.quit()
            }

            Column {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }
                spacing: units.gu(4)
                width: parent.width
                visible: !accountPage.loginInProcess

                Label {
                    id: lblTitle

                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    text: i18n.tr("Account sign-in failed. Please select your account to sign back in.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    fontSize: "large"
                }

                Button {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    text: accountPage.account.displayName
                    iconName: accountPage.getServiceIcon(accountPage.account.serviceId)
                    onClicked: {
                        accountPage.loginInProcess = true
                        account.authenticate({"ForceTokenRefresh": true})
                    }
                }
            }

            ActivityIndicator {
                id: activity

                anchors.centerIn: parent
                running: accountPage.loginInProcess
                visible: running
            }

            Component.onCompleted:  {
                if (account) {
                    account.onAuthenticationReply.connect(accountAuthenticationReply)
                } else {
                    console.warn("No account set")
                }
            }
        }
    }

    Component.onCompleted: {
        i18n.domain = GETTEXT_PACKAGE
        i18n.bindtextdomain(GETTEXT_PACKAGE, GETTEXT_LOCALEDIR)
    }
}
