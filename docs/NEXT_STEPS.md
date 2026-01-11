# Next Steps for Agent Dodo

> Immediate action items to verify the MVP

---

## 🎯 Current Priority: "See What We Wrote"

We can write posts, but we can't see them yet. The database is filling up in the dark.

### Step 1: Implement History View (Today)
**Goal:** Verify `LocalStore` is actually saving data.

**Tasks:**
1.  Create `PostMapper` (Done)
2.  Create `HistoryViewModel` (Fetch posts logic)
3.  Create `HistoryListView` (UI with List)
4.  Connect in `ContentView`

### Step 2: Implement Drafts (Next)
**Goal:** Enable "Save for later" workflow.

**Tasks:**
1.  Connect "Save Draft" button in Composer.
2.  Build `DraftsViewModel`.
3.  Build `DraftsListView` with tap-to-edit.

---

## 🛠 Manual Fixes Checklist (If Xcode complains)

If you see `Cannot find X in scope`:
1.  Select the file in Xcode.
2.  Open Right Panel (Inspectors).
3.  Check **Target Membership** [x] AgentDodo.
