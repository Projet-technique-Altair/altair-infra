<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Altaïr – Register</title>

  <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">
</head>

<body class="register-page">

<div class="scene">

  <img
    src="${url.resourcesPath}/img/titre.png"
    class="global-title"
    alt="Altaïr"
  />

  <section class="panel left">
    <img
      src="${url.resourcesPath}/img/altair-star.png"
      class="hero-star"
      alt=""
      aria-hidden="true"
    />

    <p class="hero-text">
      Start your journey<br />
      with a new account.
    </p>
  </section>

  <div class="divider"></div>

  <section class="panel right">
    <div class="login-card register-card">
      <h1>Create account</h1>
      <p class="register-intro">
        Create your Altaïr account and begin your journey.
      </p>

      <#if message?has_content>
        <div class="error">
          ${message.summary}
        </div>
      </#if>

      <form
        id="kc-register-form"
        action="${url.registrationAction}"
        method="post"
      >
        <div class="form-grid">
          <div>
            <label for="firstName">First name</label>
            <input
              id="firstName"
              name="firstName"
              type="text"
              value="${(register.formData.firstName!'')}"
              autocomplete="given-name"
            />
          </div>

          <div>
            <label for="lastName">Last name</label>
            <input
              id="lastName"
              name="lastName"
              type="text"
              value="${(register.formData.lastName!'')}"
              autocomplete="family-name"
            />
          </div>
        </div>

        <label for="email">Email</label>
        <input
          id="email"
          name="email"
          type="email"
          value="${(register.formData.email!'')}"
          autocomplete="email"
          required
        />

        <#if !realm.registrationEmailAsUsername>
          <label for="username">Username</label>
          <input
            id="username"
            name="username"
            type="text"
            value="${(register.formData.username!'')}"
            autocomplete="username"
            required
          />
        </#if>

        <label for="password">Password</label>
        <input
          id="password"
          name="password"
          type="password"
          autocomplete="new-password"
          required
        />

        <label for="password-confirm">Confirm password</label>
        <input
          id="password-confirm"
          name="password-confirm"
          type="password"
          autocomplete="new-password"
          required
        />

        <div class="register-actions">
          <a class="back-link" href="${url.loginUrl}">Back to login</a>
        </div>

        <button type="submit">Register</button>
      </form>
    </div>
  </section>

</div>

</body>
</html>
