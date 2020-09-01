// Copyright 2020 New Relic Corporation. All rights reserved.
// SPDX-License-Identifier: Apache-2.0
// +build linux
// +build harvest

package harvest

import (
	"net/http"
	"os/user"
	"testing"
	"time"

	pluginsLinux "github.com/jportasa/infrastructure-agent/internal/plugins/linux"
	"github.com/jportasa/infrastructure-agent/internal/testhelpers"
	"github.com/jportasa/infrastructure-agent/pkg/backend/inventoryapi"
	fixture "github.com/jportasa/infrastructure-agent/test/fixture/inventory"
	"github.com/jportasa/infrastructure-agent/test/infra"
	ihttp "github.com/jportasa/infrastructure-agent/test/infra/http"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestUsersPlugin(t *testing.T) {
	t.Skip("till we can report user log-in/outs happening in brief time spans")

	testhelpers.SetupLog()

	rc := ihttp.NewRequestRecorderClient()
	a := infra.NewAgent(rc.Client)
	a.RegisterPlugin(pluginsLinux.NewUsersPlugin(a.Context))

	go a.Run()

	var req http.Request
	select {
	case req = <-rc.RequestCh:
		a.Terminate()
	// this plugin seems to require extra time to fulfil
	case <-time.After(testhelpers.InventoryDuration(a.Context.Config().UsersRefreshSec)):
		a.Terminate()
		assert.FailNow(t, "timeout while waiting for a response")
	}

	current, err := user.Current()
	require.NoError(t, err)
	userName := current.Username

	fixture.AssertRequestContainsInventoryDeltas(t, req, []*inventoryapi.RawDelta{
		{
			Source:   "sessions/users",
			ID:       1,
			FullDiff: true,
			// Checking some common services that should exist in any linux host
			Diff: map[string]interface{}{
				userName: map[string]interface{}{
					"id": userName,
				},
			},
		},
	})
}
