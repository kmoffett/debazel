# Standard template for setting up a debazel package workspace
_DEBAZEL_PATH = '/usr/share/debazel/rules'
workspace(name = "debazel")
local_repository(name = "debazel_rules", path = _DEBAZEL_PATH)
load("@debazel_rules//:workspace.bzl", "debazel_workspace")
debazel_workspace()
