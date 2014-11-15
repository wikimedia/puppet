<?php

if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
  $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_X_FORWARDED_FOR'];
}
if (!empty($_SERVER['HTTP_X_FORWARDED_PROTO'])
    && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
  $_SERVER['HTTPS'] = true;
}

class redirector {
  protected $config;
  protected $mysqli;

  function __construct() {
    $this->config = json_decode(
      file_get_contents(__DIR__.'/redirect_config.json'));

    $this->mysqli = new mysqli(
      $this->config->mysql->host,
      $this->config->mysql->user,
      $this->config->mysql->pass,
      'phabricator_maniphest'
    );
    if ($this->mysqli->connect_error) {
      $msg = 'redirector.php: Connect Error (' . $this->mysqli->connect_errno . ') '
           . $this->mysqli->connect_error;
      error_log($msg);
      die($msg);
    }
  }
  public function redirect($url) {
    foreach ($this->config->urlPatterns as $i=>$p) {
      $matches = array();
      $pattern = '#'.$p->pattern.'#';

      if (preg_match( $pattern, $url, $matches )) {
        if (isset($p->fieldValue)) {
          // dynamic redirect, look up $id using cross reference query
          $fieldValue = isset($matches[1])
                      ? str_replace('$1', $matches[1], $p->fieldValue)
                      : $p->fieldValue;

          $sql = str_replace('$fieldValue', $fieldValue, $this->config->query);
          $sql = str_replace('$fieldIndex', $this->config->fieldIndex, $sql);

          if ($res = $this->mysqli->query($sql)) {
            $res = $res->fetch_assoc();
            // insert the cross referenced id into the redirectUrl
            $redirect = str_replace('$id', $res['id'], $p->redirectUrl);
            header("Location: $redirect");
            exit;
          }
        } else {
          $redirect = $p->redirectUrl;
          if (count($matches)>1) {
            for ($i = 1; $i < count($matches); $i++) {
              $redirect = str_replace('$'.$i, $matches[$i], $redirect);
            }
          }
          // static redirect
          header("Location: $redirect");
          exit;
        }
      }
    }
  }
}

if ($_SERVER['HTTP_HOST'] !== 'phabricator.wikimedia.org') {
  $full_uri = $_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];
  $r = new redirector();
  $r->redirect($full_uri);
}
