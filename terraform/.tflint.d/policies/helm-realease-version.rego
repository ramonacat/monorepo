package tflint

import rego.v1

deny_helm_release_without_version contains issue if {
    releases := terraform.resources("helm_release", {"version": "string"}, {})

    release = releases[_]
	release.config == {}

	issue := tflint.issue(`Helm releases must always have an explicit version`, release.decl_range)
}
