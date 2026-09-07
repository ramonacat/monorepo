resource "authentik_stage_invitation" "default" {
  name                             = "default invitation"
  continue_flow_without_invitation = false
}

resource "authentik_stage_prompt_field" "username" {
  name      = "username pub"
  field_key = "username"
  label     = "username"
  type      = "username"
  required  = true
  order     = 0
}

resource "authentik_stage_prompt_field" "email" {
  name      = "email pub"
  field_key = "email"
  label     = "e-mail (optional)"
  type      = "email"
  required  = false
  order     = 1
}

resource "authentik_stage_prompt_field" "password" {
  name      = "password pub"
  field_key = "password"
  label     = "password"
  type      = "password"
  required  = true
  order     = 10
}

resource "authentik_stage_prompt_field" "password-repeat" {
  name      = "password-repeat pub"
  field_key = "password_repeat"
  label     = "repeat password"
  type      = "password"
  required  = true
  order     = 11
}

resource "authentik_stage_prompt" "user-details" {
  name = "user details pub"

  fields = [
    authentik_stage_prompt_field.username.id,
    authentik_stage_prompt_field.email.id,
    authentik_stage_prompt_field.password.id,
    authentik_stage_prompt_field.password-repeat.id,
  ]
}

resource "authentik_stage_user_write" "default" {
  name                     = "user-write pub"
  create_users_as_inactive = false
  create_users_group       = authentik_group.ha-users.id
  user_type                = "internal"
}

resource "authentik_stage_user_login" "default" {
  name = "user-login pub"
}

resource "authentik_flow" "enrollment" {
  name           = "enrollment"
  title          = "enrollment"
  slug           = "enrollment"
  designation    = "enrollment"
  authentication = "require_unauthenticated"
  background     = local.flow_background
}

resource "authentik_flow_stage_binding" "enrollment--invitation" {
  target               = authentik_flow.enrollment.uuid
  stage                = authentik_stage_invitation.default.id
  order                = 0
  evaluate_on_plan     = true
  re_evaluate_policies = true
}

resource "authentik_flow_stage_binding" "enrollment--user-details" {
  target               = authentik_flow.enrollment.uuid
  stage                = authentik_stage_prompt.user-details.id
  order                = 10
  evaluate_on_plan     = true
  re_evaluate_policies = true
}
resource "authentik_flow_stage_binding" "enrollment--user-write" {
  target               = authentik_flow.enrollment.uuid
  stage                = authentik_stage_user_write.default.id
  order                = 20
  evaluate_on_plan     = true
  re_evaluate_policies = true
}

resource "authentik_flow_stage_binding" "enrollment--user-login" {
  target               = authentik_flow.enrollment.uuid
  stage                = authentik_stage_user_login.default.id
  order                = 30
  evaluate_on_plan     = true
  re_evaluate_policies = true
}

