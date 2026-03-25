# Host Integration

Use this file when a workflow depends on local installs, auth state, or same-host app-plus-browser behavior.

## Required Preflight

1. Verify the required tool is installed.
2. Verify any required auth or signed-in browser state.
3. Verify the target app and dependent tool are on the same host.
4. Run one live smoke check before claiming the integration works.

## Classification

- `unavailable`
  - install, auth, browser session, or host preflight is missing
- `failed`
  - the tool launched, but the logic or assertion was wrong

## Repo Examples

- local HTML explainer review in Edge
- browser automation or desktop/browser mixed workflows
- future local ASR service work that depends on local model/runtime availability
