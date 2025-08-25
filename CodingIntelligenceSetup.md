# Configuring Coding Intelligence in Xcode

This document explains how to enable a language model for coding
assistance in Xcode 26.  Xcode’s intelligence settings allow you to
choose an on‑device model such as ChatGPT or add a different provider
to power code completion and documentation features.

## Prerequisites

- Xcode 26 or later installed on macOS 14 or newer.
- A compatible model provider (ChatGPT or another provider
  supporting Apple’s intelligence framework).

## Steps

1. Launch **Xcode** and ensure your project is open.
2. From the menu bar choose **Xcode ▸ Settings…**.  This opens the
   settings window for the IDE.
3. In the settings window, select the **Intelligence** section from the
   sidebar.  The panel lists available models and providers.
4. To enable ChatGPT, locate the **ChatGPT** toggle and turn it on.  If
   ChatGPT is available in your region it will immediately become the
   active model for code completion and contextual suggestions.
5. To use a different model, click the **Add Model Provider** button.  A
   sheet appears prompting you to sign in or provide API details for your
   chosen provider.
6. Follow the provider’s instructions to complete the setup.  Once
   configured, the new provider will appear in the list and you can
   select it as your active model.

If you are unable to enable ChatGPT (for example due to regional
availability) you can continue using the default on‑device intelligence
model or any provider you have added.

Refer to Apple’s documentation for the most up‑to‑date information on
supported providers and feature availability.