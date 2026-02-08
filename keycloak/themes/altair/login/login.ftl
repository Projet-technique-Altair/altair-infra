<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Altaïr – Sign in</title>

  <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">
</head>

<body>

<div class="scene">

  <!-- GLOBAL TITLE -->
  <img
    src="${url.resourcesPath}/img/titre.png"
    class="global-title"
    alt="Altaïr"
  />

  <!-- LEFT HERO -->
  <section class="panel left">

    <!-- STAR -->
    <img
      src="${url.resourcesPath}/img/altair-star.png"
      class="hero-star"
      alt=""
      aria-hidden="true"
    />

    <!-- TAGLINE -->
    <p class="hero-text">
      Begin your ascent<br />
      beyond the stars.
    </p>

  </section>

  <!-- SEPARATOR -->
  <div class="divider"></div>

  <!-- RIGHT -->
  <section class="panel right">
    <div class="login-card">

      <h1>Sign in</h1>

      <#if message?has_content>
        <div class="error">
          ${message.summary}
        </div>
      </#if>

      <form
        id="kc-form-login"
        action="${url.loginAction}"
        method="post"
      >
        <label>Email</label>
        <input type="text" name="username" required />

        <label>Password</label>
        <input type="password" name="password" required />

        <button type="submit">Sign in</button>

        <div class="forgot">
          <a href="${url.loginResetCredentialsUrl}">
            Forgot password?
          </a>
        </div>
      </form>

    </div>
  </section>

</div>

</body>
</html>
