# This module allows us to create best-practices, all-inclusive k8s services with a set of powerful nix functions.
{ hex, pkgs, ... }:
let
  inherit (hex) ifNotNull ifNotEmptyList ifNotEmptyAttr toYAMLDoc;
  inherit (hex) boolToString concatMapStrings concatStringsSep filter removePrefix;
  inherit (builtins) all attrNames hasAttr isAttrs isBool isInt isList isString length;
  inherit (pkgs.lib.asserts) assertMsg;
  inherit (pkgs.lib.attrsets) mapAttrsToList;

  isNonEmptyStringList = value:
    isList value && value != [ ] && all isString value;

  isNonEmptyString = value:
    isString value && value != "";

  isValidPort = port:
    (isInt port && port >= 1 && port <= 65535)
    || isNonEmptyString port;

  isValidPercentage = value:
    isString value
    && builtins.match "([0-9]|[1-9][0-9]|100)%" value != null;

  isValidIntOrPercentage = value:
    (isInt value && value >= 0)
    || isValidPercentage value;

  isZeroIntOrPercentage = value:
    value == 0 || value == "0%";

  unknownFields = allowedFields: value:
    filter
      (field: !(builtins.elem field allowedFields))
      (attrNames value);

  isValidHttpHeader = header:
    isAttrs header
    && header ? name
    && isString header.name
    && header.name != ""
    && header ? value
    && isString header.value;

  isValidHttpGet = request:
    isAttrs request
    && request ? port
    && isValidPort request.port
    && (!(request ? host) || isString request.host)
    && (!(request ? path) || isString request.path)
    && (!(request ? scheme) || builtins.elem request.scheme [ "HTTP" "HTTPS" ])
    && (!(request ? httpHeaders) || (isList request.httpHeaders && all isValidHttpHeader request.httpHeaders));

  isValidTcpSocket = socket:
    isAttrs socket
    && socket ? port
    && isValidPort socket.port
    && (!(socket ? host) || isString socket.host);

  isValidGrpc = grpc:
    isAttrs grpc
    && grpc ? port
    && isInt grpc.port
    && grpc.port >= 1
    && grpc.port <= 65535
    && (!(grpc ? service) || isString grpc.service);

  supportedLifecycleHandlerFields = [ "exec" "httpGet" "sleep" "tcpSocket" ];
  supportedLifecycleActionFields = [ "exec" "httpGet" "sleep" ];

  validateLifecycleHandler = hookName: handler:
    assert assertMsg (isAttrs handler)
      "hex.k8s.services.build: lifecycle.${hookName} must be an attribute set";
    let
      unknownFields = filter
        (field: !(builtins.elem field supportedLifecycleHandlerFields))
        (attrNames handler);
      configuredActions = filter (field: hasAttr field handler) supportedLifecycleActionFields;
    in
    assert assertMsg (unknownFields == [ ])
      "hex.k8s.services.build: lifecycle.${hookName} has unsupported fields: ${concatStringsSep ", " unknownFields}";
    assert assertMsg (!(handler ? tcpSocket))
      "hex.k8s.services.build: lifecycle.${hookName}.tcpSocket is unsupported by Kubernetes";
    assert assertMsg (length configuredActions == 1)
      "hex.k8s.services.build: lifecycle.${hookName} must configure exactly one of exec, httpGet, or sleep";
    assert assertMsg (!(handler ? exec) || (isAttrs handler.exec && handler.exec ? command && isNonEmptyStringList handler.exec.command))
      "hex.k8s.services.build: lifecycle.${hookName}.exec.command must be a non-empty list of strings";
    assert assertMsg (!(handler ? httpGet) || isValidHttpGet handler.httpGet)
      "hex.k8s.services.build: lifecycle.${hookName}.httpGet must contain a valid port and request fields";
    assert assertMsg (!(handler ? sleep) || (isAttrs handler.sleep && handler.sleep ? seconds && isInt handler.sleep.seconds && handler.sleep.seconds > 0))
      "hex.k8s.services.build: lifecycle.${hookName}.sleep.seconds must be a positive integer";
    handler;

  validateLifecycle = lifecycle:
    if lifecycle == null then
      null
    else
      assert assertMsg (isAttrs lifecycle)
        "hex.k8s.services.build: lifecycle must be an attribute set";
      let
        supportedFields = [ "postStart" "preStop" "stopSignal" ];
        unknownFields = filter
          (field: !(builtins.elem field supportedFields))
          (attrNames lifecycle);
      in
      assert assertMsg (unknownFields == [ ])
        "hex.k8s.services.build: lifecycle has unsupported fields: ${concatStringsSep ", " unknownFields}";
      assert assertMsg (!(lifecycle ? stopSignal) || (isString lifecycle.stopSignal && lifecycle.stopSignal != ""))
        "hex.k8s.services.build: lifecycle.stopSignal must be a non-empty string";
      lifecycle
      // {
        ${if hasAttr "postStart" lifecycle then "postStart" else null} =
          validateLifecycleHandler "postStart" lifecycle.postStart;
        ${if hasAttr "preStop" lifecycle then "preStop" else null} =
          validateLifecycleHandler "preStop" lifecycle.preStop;
      };

  supportedProbeActionFields = [ "exec" "httpGet" "tcpSocket" "grpc" ];
  supportedProbeFields = supportedProbeActionFields ++ [
    "failureThreshold"
    "initialDelaySeconds"
    "periodSeconds"
    "successThreshold"
    "terminationGracePeriodSeconds"
    "timeoutSeconds"
  ];

  validateProbe = probeName: probe:
    if probe == null then
      null
    else
      assert assertMsg (isAttrs probe)
        "hex.k8s.services.build: ${probeName} must be an attribute set";
      let
        unsupportedFields = unknownFields supportedProbeFields probe;
        configuredActions = filter (field: hasAttr field probe) supportedProbeActionFields;
      in
      assert assertMsg (unsupportedFields == [ ])
        "hex.k8s.services.build: ${probeName} has unsupported fields: ${concatStringsSep ", " unsupportedFields}";
      assert assertMsg (length configuredActions == 1)
        "hex.k8s.services.build: ${probeName} must configure exactly one of exec, httpGet, tcpSocket, or grpc";
      assert assertMsg (!(probe ? exec) || (isAttrs probe.exec && probe.exec ? command && isNonEmptyStringList probe.exec.command))
        "hex.k8s.services.build: ${probeName}.exec.command must be a non-empty list of strings";
      assert assertMsg (!(probe ? httpGet) || isValidHttpGet probe.httpGet)
        "hex.k8s.services.build: ${probeName}.httpGet must contain a valid port and request fields";
      assert assertMsg (!(probe ? tcpSocket) || isValidTcpSocket probe.tcpSocket)
        "hex.k8s.services.build: ${probeName}.tcpSocket must contain a valid port and optional host";
      assert assertMsg (!(probe ? grpc) || isValidGrpc probe.grpc)
        "hex.k8s.services.build: ${probeName}.grpc must contain an integer port and optional service";
      assert assertMsg (!(probe ? initialDelaySeconds) || (isInt probe.initialDelaySeconds && probe.initialDelaySeconds >= 0))
        "hex.k8s.services.build: ${probeName}.initialDelaySeconds must be a non-negative integer";
      assert assertMsg (!(probe ? timeoutSeconds) || (isInt probe.timeoutSeconds && probe.timeoutSeconds > 0))
        "hex.k8s.services.build: ${probeName}.timeoutSeconds must be a positive integer";
      assert assertMsg (!(probe ? periodSeconds) || (isInt probe.periodSeconds && probe.periodSeconds > 0))
        "hex.k8s.services.build: ${probeName}.periodSeconds must be a positive integer";
      assert assertMsg (!(probe ? successThreshold) || (isInt probe.successThreshold && probe.successThreshold > 0))
        "hex.k8s.services.build: ${probeName}.successThreshold must be a positive integer";
      assert assertMsg (!(probe ? failureThreshold) || (isInt probe.failureThreshold && probe.failureThreshold > 0))
        "hex.k8s.services.build: ${probeName}.failureThreshold must be a positive integer";
      assert assertMsg (!(probe ? terminationGracePeriodSeconds) || (isInt probe.terminationGracePeriodSeconds && probe.terminationGracePeriodSeconds > 0))
        "hex.k8s.services.build: ${probeName}.terminationGracePeriodSeconds must be a positive integer";
      assert assertMsg (probeName != "readinessProbe" || !(probe ? terminationGracePeriodSeconds))
        "hex.k8s.services.build: readinessProbe cannot configure terminationGracePeriodSeconds";
      assert assertMsg (!(probe ? successThreshold) || builtins.elem probeName [ "probe" "readinessProbe" ] || probe.successThreshold == 1)
        "hex.k8s.services.build: ${probeName}.successThreshold must be 1";
      probe;

  probeTiming =
    { failureThreshold ? null
    , initialDelaySeconds ? null
    , periodSeconds ? null
    , successThreshold ? null
    , terminationGracePeriodSeconds ? null
    , timeoutSeconds ? null
    }: {
      ${ifNotNull failureThreshold "failureThreshold"} = failureThreshold;
      ${ifNotNull initialDelaySeconds "initialDelaySeconds"} = initialDelaySeconds;
      ${ifNotNull periodSeconds "periodSeconds"} = periodSeconds;
      ${ifNotNull successThreshold "successThreshold"} = successThreshold;
      ${ifNotNull terminationGracePeriodSeconds "terminationGracePeriodSeconds"} = terminationGracePeriodSeconds;
      ${ifNotNull timeoutSeconds "timeoutSeconds"} = timeoutSeconds;
    };

  validateDisruptionBudget = budget:
    if budget == null then
      null
    else
      assert assertMsg (isAttrs budget)
        "hex.k8s.services.build: disruptionBudget must be an attribute set";
      let
        supportedFields = [ "maxUnavailable" "minAvailable" "unhealthyPodEvictionPolicy" ];
        unsupportedFields = unknownFields supportedFields budget;
        availabilityFields = filter (field: hasAttr field budget) [ "maxUnavailable" "minAvailable" ];
      in
      assert assertMsg (unsupportedFields == [ ])
        "hex.k8s.services.build: disruptionBudget has unsupported fields: ${concatStringsSep ", " unsupportedFields}";
      assert assertMsg (length availabilityFields == 1)
        "hex.k8s.services.build: disruptionBudget must configure exactly one of minAvailable or maxUnavailable";
      assert assertMsg (!(budget ? minAvailable) || isValidIntOrPercentage budget.minAvailable)
        "hex.k8s.services.build: disruptionBudget.minAvailable must be a non-negative integer or percentage";
      assert assertMsg (!(budget ? maxUnavailable) || isValidIntOrPercentage budget.maxUnavailable)
        "hex.k8s.services.build: disruptionBudget.maxUnavailable must be a non-negative integer or percentage";
      assert assertMsg (!(budget ? unhealthyPodEvictionPolicy) || builtins.elem budget.unhealthyPodEvictionPolicy [ "AlwaysAllow" "IfHealthyBudget" ])
        "hex.k8s.services.build: disruptionBudget.unhealthyPodEvictionPolicy must be AlwaysAllow or IfHealthyBudget";
      budget;

  validateTopologySpreadConstraint = constraint:
    assert assertMsg (isAttrs constraint)
      "hex.k8s.services.build: topologySpread entries must be attribute sets";
    let
      supportedFields = [
        "matchLabelKeys"
        "maxSkew"
        "minDomains"
        "nodeAffinityPolicy"
        "nodeTaintsPolicy"
        "topologyKey"
        "whenUnsatisfiable"
      ];
      unsupportedFields = unknownFields supportedFields constraint;
    in
    assert assertMsg (unsupportedFields == [ ])
      "hex.k8s.services.build: topologySpread entry has unsupported fields: ${concatStringsSep ", " unsupportedFields}";
    assert assertMsg (constraint ? topologyKey && isNonEmptyString constraint.topologyKey)
      "hex.k8s.services.build: topologySpread entry requires a non-empty topologyKey";
    assert assertMsg (constraint ? maxSkew && isInt constraint.maxSkew && constraint.maxSkew > 0)
      "hex.k8s.services.build: topologySpread entry requires a positive maxSkew";
    assert assertMsg (constraint ? whenUnsatisfiable && builtins.elem constraint.whenUnsatisfiable [ "DoNotSchedule" "ScheduleAnyway" ])
      "hex.k8s.services.build: topologySpread.whenUnsatisfiable must be DoNotSchedule or ScheduleAnyway";
    assert assertMsg (!(constraint ? minDomains) || (isInt constraint.minDomains && constraint.minDomains > 0))
      "hex.k8s.services.build: topologySpread.minDomains must be a positive integer";
    assert assertMsg (!(constraint ? minDomains) || constraint.whenUnsatisfiable == "DoNotSchedule")
      "hex.k8s.services.build: topologySpread.minDomains requires hard scheduling";
    assert assertMsg (!(constraint ? nodeAffinityPolicy) || builtins.elem constraint.nodeAffinityPolicy [ "Honor" "Ignore" ])
      "hex.k8s.services.build: topologySpread.nodeAffinityPolicy must be Honor or Ignore";
    assert assertMsg (!(constraint ? nodeTaintsPolicy) || builtins.elem constraint.nodeTaintsPolicy [ "Honor" "Ignore" ])
      "hex.k8s.services.build: topologySpread.nodeTaintsPolicy must be Honor or Ignore";
    assert assertMsg (!(constraint ? matchLabelKeys) || (isList constraint.matchLabelKeys && all isNonEmptyString constraint.matchLabelKeys))
      "hex.k8s.services.build: topologySpread.matchLabelKeys must be a list of non-empty strings";
    constraint;

  validateContainer = context: container:
    assert assertMsg (isAttrs container)
      "hex.k8s.services.${context}: container must be an attribute set";
    assert assertMsg (container ? name && isNonEmptyString container.name)
      "hex.k8s.services.${context}: container.name must be a non-empty string";
    assert assertMsg (container ? image && isNonEmptyString container.image)
      "hex.k8s.services.${context}: container.image must be a non-empty string";
    assert assertMsg (!(container ? command) || isNonEmptyStringList container.command)
      "hex.k8s.services.${context}: container.command must be a non-empty list of strings";
    assert assertMsg (!(container ? args) || (isList container.args && all isString container.args))
      "hex.k8s.services.${context}: container.args must be a list of strings";
    container
    // {
      ${if hasAttr "lifecycle" container then "lifecycle" else null} =
        validateLifecycle container.lifecycle;
      ${if hasAttr "livenessProbe" container then "livenessProbe" else null} =
        validateProbe "livenessProbe" container.livenessProbe;
      ${if hasAttr "readinessProbe" container then "readinessProbe" else null} =
        validateProbe "readinessProbe" container.readinessProbe;
      ${if hasAttr "startupProbe" container then "startupProbe" else null} =
        validateProbe "startupProbe" container.startupProbe;
    };

  validateRollout = rollout:
    assert assertMsg (isAttrs rollout)
      "hex.k8s.services.build: rollout must be an attribute set";
    let
      supportedFields = [ "minReadySeconds" "progressDeadlineSeconds" "strategy" ];
      unsupportedFields = unknownFields supportedFields rollout;
      strategy = rollout.strategy or null;
      strategyFields = if isAttrs strategy then unknownFields [ "rollingUpdate" "type" ] strategy else [ ];
      rollingUpdate = if isAttrs strategy && strategy ? rollingUpdate then strategy.rollingUpdate else null;
      rollingUpdateFields =
        if isAttrs rollingUpdate then
          unknownFields [ "maxSurge" "maxUnavailable" ] rollingUpdate
        else
          [ ];
      minReadySeconds = rollout.minReadySeconds or 0;
    in
    assert assertMsg (unsupportedFields == [ ])
      "hex.k8s.services.build: rollout has unsupported fields: ${concatStringsSep ", " unsupportedFields}";
    assert assertMsg (isAttrs strategy && strategy ? type && builtins.elem strategy.type [ "Recreate" "RollingUpdate" ])
      "hex.k8s.services.build: rollout.strategy.type must be Recreate or RollingUpdate";
    assert assertMsg (strategyFields == [ ])
      "hex.k8s.services.build: rollout.strategy has unsupported fields: ${concatStringsSep ", " strategyFields}";
    assert assertMsg (strategy.type != "Recreate" || !(strategy ? rollingUpdate))
      "hex.k8s.services.build: Recreate rollout cannot configure rollingUpdate";
    assert assertMsg (strategy.type != "RollingUpdate" || isAttrs rollingUpdate)
      "hex.k8s.services.build: RollingUpdate rollout requires rollingUpdate settings";
    assert assertMsg (rollingUpdateFields == [ ])
      "hex.k8s.services.build: rollout.strategy.rollingUpdate has unsupported fields: ${concatStringsSep ", " rollingUpdateFields}";
    assert assertMsg (rollingUpdate == null || (rollingUpdate ? maxSurge && isValidIntOrPercentage rollingUpdate.maxSurge))
      "hex.k8s.services.build: rollout maxSurge must be a non-negative integer or percentage";
    assert assertMsg (rollingUpdate == null || (rollingUpdate ? maxUnavailable && isValidIntOrPercentage rollingUpdate.maxUnavailable))
      "hex.k8s.services.build: rollout maxUnavailable must be a non-negative integer or percentage";
    assert assertMsg (rollingUpdate == null || !(isZeroIntOrPercentage rollingUpdate.maxSurge && isZeroIntOrPercentage rollingUpdate.maxUnavailable))
      "hex.k8s.services.build: rollout maxSurge and maxUnavailable cannot both be zero";
    assert assertMsg (isInt minReadySeconds && minReadySeconds >= 0)
      "hex.k8s.services.build: rollout.minReadySeconds must be a non-negative integer";
    assert assertMsg (!(rollout ? progressDeadlineSeconds) || (isInt rollout.progressDeadlineSeconds && rollout.progressDeadlineSeconds > minReadySeconds))
      "hex.k8s.services.build: rollout.progressDeadlineSeconds must be greater than minReadySeconds";
    rollout;

  validateAutoscaling = config:
    assert assertMsg (isAttrs config)
      "hex.k8s.services.build: autoscaling must be an attribute set";
    let
      supportedFields = [ "behavior" "maxReplicas" "metrics" "minReplicas" ];
      unsupportedFields = unknownFields supportedFields config;
    in
    assert assertMsg (unsupportedFields == [ ])
      "hex.k8s.services.build: autoscaling has unsupported fields: ${concatStringsSep ", " unsupportedFields}";
    assert assertMsg (config ? minReplicas && isInt config.minReplicas && config.minReplicas > 0)
      "hex.k8s.services.build: autoscaling.minReplicas must be a positive integer";
    assert assertMsg (config ? maxReplicas && isInt config.maxReplicas && config.maxReplicas >= config.minReplicas)
      "hex.k8s.services.build: autoscaling.maxReplicas must be an integer greater than or equal to minReplicas";
    assert assertMsg (config ? metrics && isList config.metrics && config.metrics != [ ] && all isAttrs config.metrics)
      "hex.k8s.services.build: autoscaling.metrics must be a non-empty list of metric attribute sets";
    assert assertMsg (!(config ? behavior) || isAttrs config.behavior)
      "hex.k8s.services.build: autoscaling.behavior must be an attribute set";
    config;

  validateServicePort = servicePort:
    assert assertMsg (isAttrs servicePort)
      "hex.k8s.services.ports: port must be an attribute set";
    let
      supportedFields = [ "appProtocol" "name" "nodePort" "port" "protocol" "targetPort" ];
      unsupportedFields = unknownFields supportedFields servicePort;
    in
    assert assertMsg (unsupportedFields == [ ])
      "hex.k8s.services.ports: unsupported fields: ${concatStringsSep ", " unsupportedFields}";
    assert assertMsg (servicePort ? name && isNonEmptyString servicePort.name)
      "hex.k8s.services.ports: name must be a non-empty string";
    assert assertMsg (servicePort ? port && isInt servicePort.port && servicePort.port >= 1 && servicePort.port <= 65535)
      "hex.k8s.services.ports: port must be an integer between 1 and 65535";
    assert assertMsg (servicePort ? targetPort && isValidPort servicePort.targetPort)
      "hex.k8s.services.ports: targetPort must be a port number or non-empty name";
    assert assertMsg (servicePort ? protocol && builtins.elem servicePort.protocol [ "SCTP" "TCP" "UDP" ])
      "hex.k8s.services.ports: protocol must be SCTP, TCP, or UDP";
    assert assertMsg (!(servicePort ? nodePort) || (isInt servicePort.nodePort && servicePort.nodePort >= 1 && servicePort.nodePort <= 65535))
      "hex.k8s.services.ports: nodePort must be an integer between 1 and 65535";
    assert assertMsg (!(servicePort ? appProtocol) || isNonEmptyString servicePort.appProtocol)
      "hex.k8s.services.ports: appProtocol must be a non-empty string";
    servicePort;

  validateExposure = exposure:
    assert assertMsg (isAttrs exposure)
      "hex.k8s.services.build: exposure must be an attribute set";
    let
      supportedFields = [
        "allocateLoadBalancerNodePorts"
        "clusterIP"
        "externalTrafficPolicy"
        "internalTrafficPolicy"
        "loadBalancerClass"
        "loadBalancerIP"
        "ports"
        "publishNotReadyAddresses"
        "sessionAffinity"
        "type"
      ];
      unsupportedFields = unknownFields supportedFields exposure;
      validatedPorts = if exposure ? ports && isList exposure.ports then map validateServicePort exposure.ports else [ ];
      portNames = map (servicePort: servicePort.name) validatedPorts;
    in
    assert assertMsg (unsupportedFields == [ ])
      "hex.k8s.services.build: exposure has unsupported fields: ${concatStringsSep ", " unsupportedFields}";
    assert assertMsg (exposure ? type && builtins.elem exposure.type [ "ClusterIP" "LoadBalancer" "NodePort" ])
      "hex.k8s.services.build: exposure.type must be ClusterIP, LoadBalancer, or NodePort";
    assert assertMsg (validatedPorts != [ ])
      "hex.k8s.services.build: exposure.ports must be a non-empty list";
    assert assertMsg (portNames == pkgs.lib.unique portNames)
      "hex.k8s.services.build: exposure port names must be unique";
    assert assertMsg (!(exposure ? clusterIP) || (exposure.type == "ClusterIP" && isNonEmptyString exposure.clusterIP))
      "hex.k8s.services.build: exposure.clusterIP is only valid for ClusterIP exposure";
    assert assertMsg (!(exposure ? externalTrafficPolicy) || (builtins.elem exposure.type [ "LoadBalancer" "NodePort" ] && builtins.elem exposure.externalTrafficPolicy [ "Cluster" "Local" ]))
      "hex.k8s.services.build: exposure.externalTrafficPolicy requires LoadBalancer or NodePort and must be Cluster or Local";
    assert assertMsg (!(exposure ? internalTrafficPolicy) || builtins.elem exposure.internalTrafficPolicy [ "Cluster" "Local" ])
      "hex.k8s.services.build: exposure.internalTrafficPolicy must be Cluster or Local";
    assert assertMsg (!(exposure ? sessionAffinity) || builtins.elem exposure.sessionAffinity [ "ClientIP" "None" ])
      "hex.k8s.services.build: exposure.sessionAffinity must be ClientIP or None";
    assert assertMsg (!(exposure ? publishNotReadyAddresses) || isBool exposure.publishNotReadyAddresses)
      "hex.k8s.services.build: exposure.publishNotReadyAddresses must be a boolean";
    assert assertMsg (!(exposure ? loadBalancerIP) || (exposure.type == "LoadBalancer" && isNonEmptyString exposure.loadBalancerIP))
      "hex.k8s.services.build: exposure.loadBalancerIP is only valid for LoadBalancer exposure";
    assert assertMsg (!(exposure ? loadBalancerClass) || (exposure.type == "LoadBalancer" && isNonEmptyString exposure.loadBalancerClass))
      "hex.k8s.services.build: exposure.loadBalancerClass is only valid for LoadBalancer exposure";
    assert assertMsg (!(exposure ? allocateLoadBalancerNodePorts) || (exposure.type == "LoadBalancer" && isBool exposure.allocateLoadBalancerNodePorts))
      "hex.k8s.services.build: exposure.allocateLoadBalancerNodePorts is only valid for LoadBalancer exposure";
    exposure // { ports = validatedPorts; };

  normalizeVolume = volume:
    assert assertMsg (isAttrs volume)
      "hex.k8s.services.build: volumes entries must be attribute sets";
    assert assertMsg (volume ? name && isNonEmptyString volume.name)
      "hex.k8s.services.build: volume.name must be a non-empty string";
    assert assertMsg (volume ? mountPath && isNonEmptyString volume.mountPath)
      "hex.k8s.services.build: volume.mountPath must be a non-empty string";
    let
      legacySourceNames = filter
        (field:
          if field == "emptyDir" then
            volume.emptyDir or false
          else
            hasAttr field volume && volume.${field} != null)
        [ "configMap" "downwardAPI" "emptyDir" "hostPath" "projected" "pvc" "secret" ];
      hasSource = volume ? source;
      source =
        if hasSource then
          volume.source
        else if legacySourceNames == [ "pvc" ] then
          { persistentVolumeClaim.claimName = volume.pvc; }
        else if legacySourceNames == [ "secret" ] then
          {
            secret = {
              secretName = volume.secret;
              ${ifNotNull (volume.items or null) "items"} = volume.items or null;
            };
          }
        else if legacySourceNames == [ "configMap" ] then
          { configMap.name = volume.configMap; }
        else if legacySourceNames == [ "hostPath" ] then
          { hostPath.path = volume.hostPath; }
        else if legacySourceNames == [ "emptyDir" ] then
          {
            emptyDir = {
              ${ifNotNull (volume.sizeLimit or null) "sizeLimit"} = volume.sizeLimit or null;
              ${ifNotNull (volume.medium or null) "medium"} = volume.medium or null;
            };
          }
        else if legacySourceNames == [ "projected" ] then
          { inherit (volume) projected; }
        else if legacySourceNames == [ "downwardAPI" ] then
          { inherit (volume) downwardAPI; }
        else
          { };
    in
    assert assertMsg (!(hasSource && legacySourceNames != [ ]))
      "hex.k8s.services.build: volume ${volume.name} cannot combine source with legacy source fields";
    assert assertMsg (hasSource || length legacySourceNames == 1)
      "hex.k8s.services.build: volume ${volume.name} must configure exactly one source";
    assert assertMsg (isAttrs source && length (attrNames source) == 1)
      "hex.k8s.services.build: volume ${volume.name}.source must contain exactly one volume source";
    assert assertMsg (!(volume ? readOnly) || isBool volume.readOnly)
      "hex.k8s.services.build: volume ${volume.name}.readOnly must be a boolean";
    assert assertMsg (!(volume ? subPath) || volume.subPath == null || isString volume.subPath)
      "hex.k8s.services.build: volume ${volume.name}.subPath must be null or a string";
    {
      inherit (volume) mountPath name;
      inherit source;
      readOnly = volume.readOnly or true;
      subPath = volume.subPath or null;
    };

  defaults = {
    egressPolicy = [
      {
        to = [
          {
            ipBlock = {
              cidr = "0.0.0.0/0";
            };
          }
        ];
      }
    ];
    ingressPolicy = [
      {
        from = [
          {
            ipBlock = {
              cidr = "0.0.0.0/0";
            };
          }
        ];
      }
    ];
    checks = {
      liveness =
        { path ? "/healthz"
        , command ? [ "true" ]
        , port ? 8080
        , http ? true
        , scheme ? "HTTP"
        , failureThreshold ? 3
        , initialDelaySeconds ? 4
        , periodSeconds ? 4
        , successThreshold ? 1
        , timeoutSeconds ? 2
        , httpHeaders ? [ ]
        }:
        if http then {
          httpGet = {
            inherit path port scheme;
            ${ifNotEmptyList httpHeaders "httpHeaders"} = httpHeaders;
          };
          inherit failureThreshold initialDelaySeconds periodSeconds successThreshold timeoutSeconds;
        } else {
          inherit failureThreshold initialDelaySeconds periodSeconds successThreshold timeoutSeconds;
          exec = { inherit command; };
        };

    };
    nodeAffinity = { labels, hard ? false, topologyKey ? "kubernetes.io/hostname" }:
      let
        _type = if hard then "required" else "preferred";
        affinityType = "${_type}DuringSchedulingIgnoredDuringExecution";
      in
      {
        podAntiAffinity = {
          ${affinityType} = [
            {
              podAffinityTerm = {
                inherit topologyKey;
                labelSelector = {
                  matchExpressions = mapAttrsToList (k: v: { key = k; operator = "In"; values = [ v ]; }) labels;
                };
              };
              weight = 100;
            }
          ];
        };
      };
  };

  services = rec {
    disruptions = {
      maxUnavailable = value:
        validateDisruptionBudget { maxUnavailable = value; };

      minAvailable = value:
        validateDisruptionBudget { minAvailable = value; };
    };

    spread = rec {
      constraint =
        { topologyKey
        , maxSkew ? 1
        , mode ? "soft"
        , minDomains ? null
        , nodeAffinityPolicy ? null
        , nodeTaintsPolicy ? null
        , matchLabelKeys ? [ ]
        }:
          assert assertMsg (builtins.elem mode [ "hard" "soft" ])
            "hex.k8s.services.spread: mode must be hard or soft";
          validateTopologySpreadConstraint {
            inherit topologyKey maxSkew;
            whenUnsatisfiable = if mode == "hard" then "DoNotSchedule" else "ScheduleAnyway";
            ${ifNotNull minDomains "minDomains"} = minDomains;
            ${ifNotNull nodeAffinityPolicy "nodeAffinityPolicy"} = nodeAffinityPolicy;
            ${ifNotNull nodeTaintsPolicy "nodeTaintsPolicy"} = nodeTaintsPolicy;
            ${ifNotEmptyList matchLabelKeys "matchLabelKeys"} = matchLabelKeys;
          };

      zones = args:
        assert assertMsg (isAttrs args && !(args ? topologyKey))
          "hex.k8s.services.spread.zones: topologyKey is managed by the constructor";
        constraint (args // { topologyKey = "topology.kubernetes.io/zone"; });

      nodes = args:
        assert assertMsg (isAttrs args && !(args ? topologyKey))
          "hex.k8s.services.spread.nodes: topologyKey is managed by the constructor";
        constraint (args // { topologyKey = "kubernetes.io/hostname"; });
    };

    containers = {
      build =
        { env ? [ ]
        , envAttrs ? { }
        , ...
        }@container:
          assert assertMsg (isList env)
            "hex.k8s.services.containers.build: env must be a list";
          assert assertMsg (isAttrs envAttrs)
            "hex.k8s.services.containers.build: envAttrs must be an attribute set";
          let
            combinedEnv = env ++ hex.envAttrToNVP envAttrs;
            normalized =
              builtins.removeAttrs container [ "env" "envAttrs" ]
              // {
                ${ifNotEmptyList combinedEnv "env"} = combinedEnv;
              };
          in
          validateContainer "containers.build" normalized;
    };

    probes = {
      exec =
        { command
        , failureThreshold ? null
        , initialDelaySeconds ? null
        , periodSeconds ? null
        , successThreshold ? null
        , terminationGracePeriodSeconds ? null
        , timeoutSeconds ? null
        }:
        validateProbe "probe"
          (actions.exec command
            // probeTiming {
            inherit failureThreshold initialDelaySeconds periodSeconds successThreshold terminationGracePeriodSeconds timeoutSeconds;
          });

      httpGet =
        { port
        , path ? "/"
        , host ? null
        , scheme ? "HTTP"
        , httpHeaders ? [ ]
        , failureThreshold ? null
        , initialDelaySeconds ? null
        , periodSeconds ? null
        , successThreshold ? null
        , terminationGracePeriodSeconds ? null
        , timeoutSeconds ? null
        }:
        validateProbe "probe"
          (actions.httpGet
            {
              inherit port path host scheme httpHeaders;
            }
          // probeTiming {
            inherit failureThreshold initialDelaySeconds periodSeconds successThreshold terminationGracePeriodSeconds timeoutSeconds;
          });

      tcpSocket =
        { port
        , host ? null
        , failureThreshold ? null
        , initialDelaySeconds ? null
        , periodSeconds ? null
        , successThreshold ? null
        , terminationGracePeriodSeconds ? null
        , timeoutSeconds ? null
        }:
        validateProbe "probe"
          ({
            tcpSocket = {
              inherit port;
              ${ifNotNull host "host"} = host;
            };
          }
          // probeTiming {
            inherit failureThreshold initialDelaySeconds periodSeconds successThreshold terminationGracePeriodSeconds timeoutSeconds;
          });

      grpc =
        { port
        , service ? null
        , failureThreshold ? null
        , initialDelaySeconds ? null
        , periodSeconds ? null
        , successThreshold ? null
        , terminationGracePeriodSeconds ? null
        , timeoutSeconds ? null
        }:
        validateProbe "probe"
          ({
            grpc = {
              inherit port;
              ${ifNotNull service "service"} = service;
            };
          }
          // probeTiming {
            inherit failureThreshold initialDelaySeconds periodSeconds successThreshold terminationGracePeriodSeconds timeoutSeconds;
          });
    };

    rollouts = {
      rolling =
        { maxSurge ? 1
        , maxUnavailable ? 1
        , minReadySeconds ? null
        , progressDeadlineSeconds ? null
        }:
        validateRollout {
          strategy = {
            type = "RollingUpdate";
            rollingUpdate = { inherit maxSurge maxUnavailable; };
          };
          ${ifNotNull minReadySeconds "minReadySeconds"} = minReadySeconds;
          ${ifNotNull progressDeadlineSeconds "progressDeadlineSeconds"} = progressDeadlineSeconds;
        };

      recreate =
        { minReadySeconds ? null
        , progressDeadlineSeconds ? null
        }:
        validateRollout {
          strategy.type = "Recreate";
          ${ifNotNull minReadySeconds "minReadySeconds"} = minReadySeconds;
          ${ifNotNull progressDeadlineSeconds "progressDeadlineSeconds"} = progressDeadlineSeconds;
        };
    };

    autoscaling = rec {
      metrics = rec {
        resourceUtilization = { name, target }:
          assert assertMsg (isNonEmptyString name)
            "hex.k8s.services.autoscaling.metrics.resourceUtilization: name must be a non-empty string";
          assert assertMsg (isInt target && target > 0)
            "hex.k8s.services.autoscaling.metrics.resourceUtilization: target must be a positive integer";
          {
            type = "Resource";
            resource = {
              inherit name;
              target = {
                type = "Utilization";
                averageUtilization = target;
              };
            };
          };

        resourceAverageValue = { name, value }:
          assert assertMsg (isNonEmptyString name)
            "hex.k8s.services.autoscaling.metrics.resourceAverageValue: name must be a non-empty string";
          assert assertMsg (isNonEmptyString value)
            "hex.k8s.services.autoscaling.metrics.resourceAverageValue: value must be a non-empty quantity";
          {
            type = "Resource";
            resource = {
              inherit name;
              target = {
                type = "AverageValue";
                averageValue = value;
              };
            };
          };

        cpuUtilization = target:
          resourceUtilization { name = "cpu"; inherit target; };

        memoryUtilization = target:
          resourceUtilization { name = "memory"; inherit target; };

        pods =
          { name
          , value
          , selector ? null
          }:
            assert assertMsg (isNonEmptyString name)
              "hex.k8s.services.autoscaling.metrics.pods: name must be a non-empty string";
            assert assertMsg (isNonEmptyString value)
              "hex.k8s.services.autoscaling.metrics.pods: value must be a non-empty quantity";
            assert assertMsg (selector == null || isAttrs selector)
              "hex.k8s.services.autoscaling.metrics.pods: selector must be null or an attribute set";
            {
              type = "Pods";
              pods = {
                metric = {
                  inherit name;
                  ${ifNotNull selector "selector"} = selector;
                };
                target = {
                  type = "AverageValue";
                  averageValue = value;
                };
              };
            };

        external =
          { name
          , value ? null
          , averageValue ? null
          , selector ? null
          }:
            assert assertMsg (isNonEmptyString name)
              "hex.k8s.services.autoscaling.metrics.external: name must be a non-empty string";
            assert assertMsg ((value == null) != (averageValue == null))
              "hex.k8s.services.autoscaling.metrics.external: configure exactly one of value or averageValue";
            assert assertMsg (value == null || isNonEmptyString value)
              "hex.k8s.services.autoscaling.metrics.external: value must be a non-empty quantity";
            assert assertMsg (averageValue == null || isNonEmptyString averageValue)
              "hex.k8s.services.autoscaling.metrics.external: averageValue must be a non-empty quantity";
            assert assertMsg (selector == null || isAttrs selector)
              "hex.k8s.services.autoscaling.metrics.external: selector must be null or an attribute set";
            {
              type = "External";
              external = {
                metric = {
                  inherit name;
                  ${ifNotNull selector "selector"} = selector;
                };
                target =
                  if value != null then
                    {
                      type = "Value";
                      inherit value;
                    }
                  else
                    {
                      type = "AverageValue";
                      inherit averageValue;
                    };
              };
            };
      };

      v2 =
        { metrics
        , min ? 2
        , max ? 4
        , behavior ? null
        }:
        validateAutoscaling {
          minReplicas = min;
          maxReplicas = max;
          inherit metrics;
          ${ifNotNull behavior "behavior"} = behavior;
        };

      cpu =
        { target ? 75
        , min ? 2
        , max ? 4
        , behavior ? null
        }:
        v2 {
          inherit min max behavior;
          metrics = [ (metrics.cpuUtilization target) ];
        };
    };

    ports = {
      build =
        { name
        , port
        , targetPort ? port
        , protocol ? "TCP"
        , nodePort ? null
        , appProtocol ? null
        }: validateServicePort {
          inherit name port targetPort protocol;
          ${ifNotNull nodePort "nodePort"} = nodePort;
          ${ifNotNull appProtocol "appProtocol"} = appProtocol;
        };

      tcp = args:
        ports.build (args // { protocol = "TCP"; });

      udp = args:
        ports.build (args // { protocol = "UDP"; });

      sctp = args:
        ports.build (args // { protocol = "SCTP"; });
    };

    exposures = {
      build = validateExposure;

      clusterIP =
        { ports
        , internalTrafficPolicy ? null
        , publishNotReadyAddresses ? null
        , sessionAffinity ? null
        }:
        validateExposure {
          type = "ClusterIP";
          inherit ports;
          ${ifNotNull internalTrafficPolicy "internalTrafficPolicy"} = internalTrafficPolicy;
          ${ifNotNull publishNotReadyAddresses "publishNotReadyAddresses"} = publishNotReadyAddresses;
          ${ifNotNull sessionAffinity "sessionAffinity"} = sessionAffinity;
        };

      headless =
        { ports
        , publishNotReadyAddresses ? null
        }:
        validateExposure {
          type = "ClusterIP";
          clusterIP = "None";
          inherit ports;
          ${ifNotNull publishNotReadyAddresses "publishNotReadyAddresses"} = publishNotReadyAddresses;
        };

      nodePort =
        { ports
        , externalTrafficPolicy ? null
        , internalTrafficPolicy ? null
        , sessionAffinity ? null
        }:
        validateExposure {
          type = "NodePort";
          inherit ports;
          ${ifNotNull externalTrafficPolicy "externalTrafficPolicy"} = externalTrafficPolicy;
          ${ifNotNull internalTrafficPolicy "internalTrafficPolicy"} = internalTrafficPolicy;
          ${ifNotNull sessionAffinity "sessionAffinity"} = sessionAffinity;
        };

      loadBalancer =
        { ports
        , externalTrafficPolicy ? null
        , internalTrafficPolicy ? null
        , sessionAffinity ? null
        , loadBalancerIP ? null
        , loadBalancerClass ? null
        , allocateLoadBalancerNodePorts ? null
        }:
        validateExposure {
          type = "LoadBalancer";
          inherit ports;
          ${ifNotNull externalTrafficPolicy "externalTrafficPolicy"} = externalTrafficPolicy;
          ${ifNotNull internalTrafficPolicy "internalTrafficPolicy"} = internalTrafficPolicy;
          ${ifNotNull sessionAffinity "sessionAffinity"} = sessionAffinity;
          ${ifNotNull loadBalancerIP "loadBalancerIP"} = loadBalancerIP;
          ${ifNotNull loadBalancerClass "loadBalancerClass"} = loadBalancerClass;
          ${ifNotNull allocateLoadBalancerNodePorts "allocateLoadBalancerNodePorts"} = allocateLoadBalancerNodePorts;
        };
    };

    volumes = rec {
      build = normalizeVolume;

      emptyDir =
        { name
        , mountPath
        , readOnly ? false
        , subPath ? null
        , sizeLimit ? null
        , medium ? null
        }:
        build {
          inherit name mountPath readOnly subPath;
          source.emptyDir = {
            ${ifNotNull sizeLimit "sizeLimit"} = sizeLimit;
            ${ifNotNull medium "medium"} = medium;
          };
        };

      pvc =
        { name
        , mountPath
        , claimName ? name
        , readOnly ? true
        , subPath ? null
        }:
        build {
          inherit name mountPath readOnly subPath;
          source.persistentVolumeClaim = { inherit claimName; };
        };

      secret =
        { name
        , mountPath
        , secretName ? name
        , readOnly ? true
        , subPath ? null
        , items ? [ ]
        , optional ? null
        , defaultMode ? null
        }:
        build {
          inherit name mountPath readOnly subPath;
          source.secret = {
            inherit secretName;
            ${ifNotEmptyList items "items"} = items;
            ${ifNotNull optional "optional"} = optional;
            ${ifNotNull defaultMode "defaultMode"} = defaultMode;
          };
        };

      configMap =
        { name
        , mountPath
        , configMapName ? name
        , readOnly ? true
        , subPath ? null
        , items ? [ ]
        , optional ? null
        , defaultMode ? null
        }:
        build {
          inherit name mountPath readOnly subPath;
          source.configMap = {
            name = configMapName;
            ${ifNotEmptyList items "items"} = items;
            ${ifNotNull optional "optional"} = optional;
            ${ifNotNull defaultMode "defaultMode"} = defaultMode;
          };
        };

      hostPath =
        { name
        , mountPath
        , path
        , type ? null
        , readOnly ? false
        , subPath ? null
        }:
          assert assertMsg (isNonEmptyString path)
            "hex.k8s.services.volumes.hostPath: path must be a non-empty string";
          build {
            inherit name mountPath readOnly subPath;
            source.hostPath = {
              inherit path;
              ${ifNotNull type "type"} = type;
            };
          };

      projected =
        { name
        , mountPath
        , sources
        , readOnly ? true
        , subPath ? null
        , defaultMode ? null
        }:
          assert assertMsg (isList sources && sources != [ ] && all isAttrs sources)
            "hex.k8s.services.volumes.projected: sources must be a non-empty list of attribute sets";
          build {
            inherit name mountPath readOnly subPath;
            source.projected = {
              inherit sources;
              ${ifNotNull defaultMode "defaultMode"} = defaultMode;
            };
          };

      downwardAPI =
        { name
        , mountPath
        , items
        , readOnly ? true
        , subPath ? null
        , defaultMode ? null
        }:
          assert assertMsg (isList items && items != [ ] && all isAttrs items)
            "hex.k8s.services.volumes.downwardAPI: items must be a non-empty list of attribute sets";
          build {
            inherit name mountPath readOnly subPath;
            source.downwardAPI = {
              inherit items;
              ${ifNotNull defaultMode "defaultMode"} = defaultMode;
            };
          };
    };

    actions = {
      exec = command:
        assert assertMsg (isNonEmptyStringList command)
          "hex.k8s.services.actions.exec: command must be a non-empty list of strings";
        {
          exec = { inherit command; };
        };

      httpGet =
        { port
        , path ? "/"
        , host ? null
        , scheme ? "HTTP"
        , httpHeaders ? [ ]
        }:
          assert assertMsg (isValidPort port)
            "hex.k8s.services.actions.httpGet: port must be a non-empty name or an integer between 1 and 65535";
          assert assertMsg (isString path)
            "hex.k8s.services.actions.httpGet: path must be a string";
          assert assertMsg (host == null || isString host)
            "hex.k8s.services.actions.httpGet: host must be null or a string";
          assert assertMsg (builtins.elem scheme [ "HTTP" "HTTPS" ])
            "hex.k8s.services.actions.httpGet: scheme must be HTTP or HTTPS";
          assert assertMsg (isList httpHeaders && all isValidHttpHeader httpHeaders)
            "hex.k8s.services.actions.httpGet: httpHeaders must contain name/value string pairs";
          {
            httpGet = {
              inherit path port scheme;
              ${ifNotNull host "host"} = host;
              ${ifNotEmptyList httpHeaders "httpHeaders"} = httpHeaders;
            };
          };

      sleep = seconds:
        assert assertMsg (isInt seconds && seconds > 0)
          "hex.k8s.services.actions.sleep: seconds must be a positive integer";
        {
          sleep = { inherit seconds; };
        };
    };

    build =
      { name
      , labels
      , image
      , namespace ? "default"
      , min ? replicas
      , max ? replicas * 2
      , autoscale ? true
      , autoscaling ? null # validated autoscaling/v2 config; defaults to the legacy CPU target
      , networkPolicy ? true
      , serviceAccount ? true
      , serviceAccountToken ? false
      , roleBinding ? true
      , port ? 443
      , altPort ? null
      , extraServicePorts ? [ ]
      , cpuUtilization ? 75
      , replicas ? 2
      , revisionHistoryLimit ? 2
      , maxSurge ? 1
      , maxUnavailable ? 1
      , rollout ? null          # use services.rollouts for Deployment strategy and readiness policy
      , disruptionBudget ? null # use services.disruptions; emits a selector-coupled PDB
      , cpuRequest ? "400m"
      , cpuLimit ? null
      , memoryRequest ? "1Gi"
      , memoryLimit ? null
      , ephemeralStorageRequest ? null
      , ephemeralStorageLimit ? null
      , command ? null
      , args ? null
      , env ? [ ]              # env vars, standard spec
      , envAttrs ? { }         # env vars, as a nix attrset
      , envFrom ? [ ]          # envFrom standard spec
      , volumes ? [ ]          # our custom format for volume
      , initContainers ? null  # will only add to main container
      , sidecars ? [ ]         # additional containers; use services.containers.build
      , ip ? null
      , service ? true
      , exposure ? null # typed Service spec from services.exposures
      , loadBalancer ? false
      , ingress ? false
      , nodePort ? false
      , subdomain ? null
      , nodeSelector ? null
      , tolerations ? null
      , topologySpread ? [ ] # constraints from services.spread; selectors are derived from labels
      , terminationGracePeriodSeconds ? null # total budget for preStop and process shutdown
      , lifecycle ? null                      # main container lifecycle; use services.actions for handlers
      , livenessProbe ? null
      , readinessProbe ? null
      , startupProbe ? null
      , securityContext ? null
      , egressPolicy ? defaults.egressPolicy
      , ingressPolicy ? defaults.ingressPolicy
      , daemonSet ? false
      , suffix ? ""
      , depSuffix ? "${suffix}"
      , saSuffix ? "-service-account${suffix}"
      , npSuffix ? "-policy${suffix}"
      , rbSuffix ? "-role-binding-view${suffix}"
      , hpaSuffix ? "-hpa${suffix}"
      , pdbSuffix ? "-pdb${suffix}"
      , serviceSuffix ? "-service${suffix}"
      , ingressSuffix ? "-ingress${suffix}"
      , tsSuffix ? "-ts${suffix}"
      , pre1_18 ? false
      , pre1_30 ? false
      , host ? null
      , extraContainer ? { }
      , extraPodSpec ? { } # additional PodSpec fields; Hex-managed fields cannot be replaced
      , extraDeploymentAnnotations ? { }
      , extraServiceAccountAnnotations ? { }
      , extraServiceAnnotations ? { }
      , extraIngressAnnotations ? { }
      , extraPodAnnotations ? { }
      , imagePullSecrets ? [ ]
      , ingressTLSSecret ? ""
      , softAntiAffinity ? false
      , hardAntiAffinity ? false
      , disableHttp ? true
      , tailscaleSidecar ? false
      , tailscale_image_base ? hex.k8s.tailscale.defaults.tailscale_image_base
      , tailscale_image_tag ? hex.k8s.tailscale.defaults.tailscale_image_tag
      , hostAliases ? [ ]
      , appArmor ? if pre1_30 then "unconfined" else "Unconfined"
      , extraDep ? { }
      , extraSA ? { }
      , extraNP ? { }
      , extraRB ? { }
      , extraHPA ? { }
      , extraPDB ? { } # top-level PDB escape hatch; requires disruptionBudget
      , extraSvc ? { }
      , extraIng ? { }
      , __init ? false
      }:
      let
        affinity =
          if softAntiAffinity then defaults.nodeAffinity { inherit labels; }
          else if hardAntiAffinity then defaults.nodeAffinity { inherit labels; hard = true; }
          else { };
        sa = (components.service-account {
          inherit name namespace saSuffix imagePullSecrets;
          annotations = extraServiceAccountAnnotations;
        }) // extraSA;
        sa-token = components.service-account-token {
          inherit name namespace saSuffix;
        };
        rb = (components.role-binding {
          inherit name namespace rbSuffix saSuffix;
        }) // extraRB;
        ts_r = hex.k8s.tailscale.role { inherit namespace; name = "${name}${tsSuffix}"; };
        ts_rb = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "RoleBinding";
          metadata = {
            name = "${name}-tailscale";
            inherit namespace;
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "Role";
            name = "${name}${tsSuffix}";
          };
          subjects = [
            {
              kind = "ServiceAccount";
              name = "${name}${saSuffix}";
            }
          ];
        };
        ts_secret = hex.k8s.tailscale.secret { inherit namespace; name = "${name}${tsSuffix}"; };
        np = (components.network-policy {
          inherit name namespace labels npSuffix;
          egress = egressPolicy;
          ingress = ingressPolicy;
        }) // extraNP;
        validatedDisruptionBudget = validateDisruptionBudget disruptionBudget;
        effectiveAutoscaling =
          if autoscaling == null then
            validateAutoscaling
              {
                minReplicas = min;
                maxReplicas = max;
                metrics = [
                  {
                    type = "Resource";
                    resource = {
                      name = "cpu";
                      target = {
                        type = "Utilization";
                        averageUtilization = cpuUtilization;
                      };
                    };
                  }
                ];
              }
          else
            validateAutoscaling autoscaling;
        validatedExposure =
          if exposure == null then
            null
          else
            validateExposure exposure;
        primaryServicePort =
          if validatedExposure == null then
            port
          else
            (builtins.head validatedExposure.ports).port;
        dep = (components.deployment {
          inherit name namespace labels image replicas revisionHistoryLimit port maxSurge maxUnavailable rollout depSuffix saSuffix daemonSet lifecycle imagePullSecrets affinity initContainers sidecars;
          inherit terminationGracePeriodSeconds startupProbe topologySpread extraPodSpec;
          inherit cpuRequest memoryRequest ephemeralStorageRequest cpuLimit memoryLimit ephemeralStorageLimit command args volumes subdomain nodeSelector livenessProbe readinessProbe securityContext;
          inherit env envAttrs envFrom extraContainer extraDeploymentAnnotations extraPodAnnotations appArmor tailscaleSidecar tailscale_image_base tailscale_image_tag tsSuffix hostAliases __init pre1_30 tolerations;
        }) // extraDep;
        hpa = (components.hpa {
          inherit name namespace labels hpaSuffix;
          config = effectiveAutoscaling;
          targetName = "${name}${depSuffix}";
        }) // extraHPA;
        pdb = (components.pdb {
          inherit name namespace labels pdbSuffix;
          budget = validatedDisruptionBudget;
        }) // extraPDB;
        svc =
          (if exposure != null then
            components.exposed-service
              {
                inherit name namespace labels serviceSuffix extraServiceAnnotations;
                exposure = validatedExposure;
              }
          else if nodePort then
            components.nodeport-service { inherit name namespace labels port serviceSuffix extraServiceAnnotations; }
          else if loadBalancer then
            components.lb-service { inherit name namespace labels port altPort ip serviceSuffix extraServiceAnnotations; }
          else
            components.service { inherit name namespace labels port altPort serviceSuffix extraServiceAnnotations; extraPorts = extraServicePorts; }) // extraSvc;
        ing = (components.ingress {
          inherit name namespace ingressSuffix serviceSuffix pre1_18 host extraIngressAnnotations disableHttp;
          port = primaryServicePort;
          tls = ingressTLSSecret;
        }) // extraIng;
      in
      assert assertMsg (!(daemonSet && autoscale))
        "hex.k8s.services.build: autoscaling is unsupported for DaemonSet workloads";
      assert assertMsg (!(daemonSet && rollout != null))
        "hex.k8s.services.build: rollout is only supported for Deployment workloads";
      assert assertMsg (!(daemonSet && disruptionBudget != null))
        "hex.k8s.services.build: disruptionBudget is only supported for Deployment workloads";
      assert assertMsg (autoscale || autoscaling == null)
        "hex.k8s.services.build: autoscaling configuration requires autoscale = true";
      assert assertMsg (exposure == null || (!nodePort && !loadBalancer))
        "hex.k8s.services.build: exposure cannot be combined with nodePort or loadBalancer";
      assert assertMsg (exposure == null || service)
        "hex.k8s.services.build: exposure requires service = true";
      assert assertMsg (exposure == null || (altPort == null && extraServicePorts == [ ]))
        "hex.k8s.services.build: exposure cannot be combined with altPort or extraServicePorts";
      assert assertMsg (!ingress || service)
        "hex.k8s.services.build: ingress requires service = true";
      assert assertMsg (disruptionBudget != null || extraPDB == { })
        "hex.k8s.services.build: extraPDB requires disruptionBudget";
      ''
        ${if serviceAccountToken then toYAMLDoc sa-token else ""}
        ${if serviceAccount then toYAMLDoc sa else ""}
        ${if roleBinding then toYAMLDoc rb else ""}
        ${if tailscaleSidecar then toYAMLDoc ts_r else ""}
        ${if tailscaleSidecar then toYAMLDoc ts_rb else ""}
        ${if tailscaleSidecar then toYAMLDoc ts_secret else ""}
        ${toYAMLDoc dep}
        ${if disruptionBudget != null then toYAMLDoc pdb else ""}
        ${if service then toYAMLDoc svc else ""}
        ${if autoscale then toYAMLDoc hpa else ""}
        ${if networkPolicy then toYAMLDoc np else ""}
        ${if ingress then toYAMLDoc ing else ""}
      '';
    components = {
      volumes = {
        tmp = {
          name = "tmp";
          mountPath = "/tmp";
          emptyDir = true;
          readOnly = false;
        };
      };
      service-account-token = { name, namespace ? "default", saSuffix ? "-sa" }: {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          inherit namespace;
          annotations = {
            "kubernetes.io/service-account.name" = "${name}${saSuffix}";
          };
          name = "${name}${saSuffix}-token";
        };
        type = "kubernetes.io/service-account-token";
      };
      service-account = { name, namespace ? "default", saSuffix ? "-sa", imagePullSecrets ? [ ], annotations ? { } }: {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          inherit namespace;
          annotations = annotations // hex.annotations;
          name = "${name}${saSuffix}";
        };
        ${ifNotEmptyList imagePullSecrets "imagePullSecrets"} = imagePullSecrets;
      };
      role = { name, rules, namespace ? "default", extraConfig ? { } }: {
        inherit rules;
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "Role";
        metadata = {
          inherit name namespace;
        };
      } // extraConfig;
      role-binding = { name, namespace ? "default", rbSuffix ? "-rb-view", saSuffix ? "-sa", extraConfig ? { } }: {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "RoleBinding";
        metadata = {
          inherit namespace;
          name = "${name}${rbSuffix}";
          annotations = { } // hex.annotations;
        };
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "view";
        };
        subjects = [
          {
            inherit namespace;
            kind = "ServiceAccount";
            name = "${name}${saSuffix}";
          }
        ];
      } // extraConfig;
      network-policy =
        { name
        , labels
        , egress ? defaults.egressPolicy
        , ingress ? defaults.ingressPolicy
        , namespace ? "default"
        , npSuffix ? "-np"
        , extraConfig ? { }
        }: {
          apiVersion = "networking.k8s.io/v1";
          kind = "NetworkPolicy";
          metadata = {
            inherit namespace;
            name = "${name}${npSuffix}";
            annotations = { } // hex.annotations;
          };
          spec = {
            inherit egress ingress;
            podSelector = {
              matchLabels = labels;
            };
            policyTypes = [
              "Ingress"
              "Egress"
            ];
          };
        } // extraConfig;

      hpa =
        { name
        , labels
        , config ? null
        , min ? 2
        , max ? 4
        , cpuUtilization ? 80
        , targetName ? name
        , namespace ? "default"
        , hpaSuffix ? "-hpa"
        , extraConfig ? { }
        }:
        let
          effectiveConfig =
            if config == null then
              validateAutoscaling
                {
                  minReplicas = min;
                  maxReplicas = max;
                  metrics = [
                    {
                      type = "Resource";
                      resource = {
                        name = "cpu";
                        target = {
                          type = "Utilization";
                          averageUtilization = cpuUtilization;
                        };
                      };
                    }
                  ];
                }
            else
              validateAutoscaling config;
        in
        {
          apiVersion = "autoscaling/v2";
          kind = "HorizontalPodAutoscaler";
          metadata = {
            inherit labels namespace;
            name = "${name}${hpaSuffix}";
            annotations = { } // hex.annotations;
          };
          spec = {
            scaleTargetRef = {
              name = targetName;
              apiVersion = "apps/v1";
              kind = "Deployment";
            };
          } // effectiveConfig;
        } // extraConfig;

      pdb =
        { name
        , labels
        , budget
        , namespace ? "default"
        , pdbSuffix ? "-pdb"
        , extraConfig ? { }
        }: {
          apiVersion = "policy/v1";
          kind = "PodDisruptionBudget";
          metadata = {
            inherit namespace labels;
            name = "${name}${pdbSuffix}";
            annotations = { } // hex.annotations;
          };
          spec = {
            selector.matchLabels = labels;
          } // budget;
        } // extraConfig;

      exposed-service =
        { name
        , labels
        , exposure
        , namespace ? "default"
        , serviceSuffix ? "-service"
        , extraServiceAnnotations ? { }
        , extraConfig ? { }
        }: {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            labels = {
              name = "${name}${serviceSuffix}";
            };
            name = "${name}${serviceSuffix}";
            annotations = { } // hex.annotations // extraServiceAnnotations;
          };
          spec = exposure // { selector = labels; };
        } // extraConfig;

      service =
        { name
        , labels
        , port ? 443
        , altPort ? null
        , extraPorts ? [ ]
        , namespace ? "default"
        , serviceSuffix ? "-service"
        , extraServiceAnnotations ? { }
        , extraConfig ? { }
        }: {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            labels = {
              name = "${name}${serviceSuffix}";
            };
            name = "${name}${serviceSuffix}";
            annotations = { } // hex.annotations // extraServiceAnnotations;
          };
          spec = {
            ports = [
              {
                inherit port;
                name = "application";
                targetPort = port;
                protocol = "TCP";
              }
            ] ++ (if altPort != null then [{
              port = altPort;
              name = "application-alt";
              targetPort = altPort;
              protocol = "TCP";
            }] else [ ])
            ++ extraPorts;
            selector = labels;
            type = "ClusterIP";
          };
        } // extraConfig;

      nodeport-service =
        { name
        , labels
        , port ? 8080
        , namespace ? "default"
        , serviceSuffix ? "-service"
        , extraServiceAnnotations ? { }
        , extraConfig ? { }
        }: {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            labels = {
              name = "${name}${serviceSuffix}";
            };
            name = "${name}${serviceSuffix}";
            annotations = { } // hex.annotations // extraServiceAnnotations;
          };
          spec = {
            ports = [
              {
                inherit port;
                name = "application";
                targetPort = port;
                protocol = "TCP";
              }
            ];
            selector = labels;
            type = "NodePort";
          };
        } // extraConfig;

      lb-service =
        { name
        , labels
        , ip
        , port ? 443
        , altPort ? null
        , namespace ? "default"
        , serviceSuffix ? "-service"
        , extraServiceAnnotations ? { }
        , extraConfig ? { }
        }: {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            labels = {
              name = "${name}${serviceSuffix}";
            };
            name = "${name}${serviceSuffix}";
            annotations = { } // hex.annotations // extraServiceAnnotations;
          };
          spec = {
            ports = [
              {
                inherit port;
                name = "application";
                targetPort = port;
                protocol = "TCP";
              }
            ] ++ (if altPort != null then [{
              port = altPort;
              name = "application-alt";
              targetPort = altPort;
              protocol = "TCP";
            }] else [ ]);
            selector = labels;
            type = "LoadBalancer";
            loadBalancerIP = ip;
            externalTrafficPolicy = "Local";
            externalIPs = [ ip ];
          };
        } // extraConfig;

      deployment =
        let
          volumeDef = volume:
            { inherit (volume) name; } // volume.source;
          volumeMountDef = { name, mountPath, readOnly, subPath, ... }: {
            inherit name mountPath readOnly;
            ${ifNotNull subPath "subPath"} = subPath;
          };
        in
        { name
        , labels
        , image
        , replicas ? 2
        , revisionHistoryLimit ? 2
        , maxSurge ? 1
        , maxUnavailable ? 1
        , rollout ? null
        , cpuRequest ? "400m"
        , cpuLimit ? null
        , memoryRequest ? "1Gi"
        , memoryLimit ? null
        , ephemeralStorageRequest ? null
        , ephemeralStorageLimit ? null
        , namespace ? "default"
        , depSuffix ? ""
        , saSuffix ? "-sa"
        , tsSuffix ? "-ts"
        , port ? null
        , command ? null
        , args ? null
        , env ? [ ]
        , envAttrs ? { }
        , envFrom ? [ ]
        , volumes ? [ ]
        , initContainers ? null
        , sidecars ? [ ]
        , subdomain ? null
        , nodeSelector ? null
        , tolerations ? null
        , topologySpread ? [ ]
        , terminationGracePeriodSeconds ? null
        , livenessProbe ? null
        , readinessProbe ? null
        , startupProbe ? null
        , securityContext ? null
        , lifecycle ? null
        , daemonSet ? false
        , imagePullSecrets ? [ ]
        , affinity ? { }
        , extraContainer ? { }
        , extraPodSpec ? { }
        , extraDeploymentAnnotations ? { }
        , extraPodAnnotations ? { }
        , appArmor ? if pre1_30 then "unconfined" else "Unconfined"
        , tailscaleSidecar ? false
        , tailscale_tags ? [ ]
        , default_tailscale_tags ? [ "k8s" "proxy" ]
        , all_tailscale_tags ? tailscale_tags ++ default_tailscale_tags
        , tailscale_image_base ? hex.k8s.tailscale.defaults.tailscale_image_base
        , tailscale_image_tag ? hex.k8s.tailscale.defaults.tailscale_image_tag
        , tailscale_stateful_filtering ? false
        , tailscale_extra_args ? [ ]
        , hostAliases ? [ ]
        , __init ? false
        , pre1_30 ? false
        }:
        let
          joinTags = concatMapStrings (x: ",tag:${x}");
          depName = "${name}${depSuffix}";
          _tags = removePrefix "," (joinTags all_tailscale_tags);
          advertise_tags_flag = if builtins.length all_tailscale_tags != 0 then "--advertise-tags=${_tags}" else null;
          stateful_filtering = "--stateful-filtering=${boolToString tailscale_stateful_filtering}";
          _extra_args = filter (x: x != null) ([
            advertise_tags_flag
            stateful_filtering
          ] ++ tailscale_extra_args);
          ts_extra_args = concatStringsSep " " _extra_args;
          sec_context = if pre1_30 then securityContext else (if securityContext != null then securityContext else { }) // { appArmorProfile.type = appArmor; };
          oldAppArmor = appArmor != null && pre1_30;
          validatedLifecycle = validateLifecycle lifecycle;
          validatedLivenessProbe = validateProbe "livenessProbe" livenessProbe;
          validatedReadinessProbe = validateProbe "readinessProbe" readinessProbe;
          validatedStartupProbe = validateProbe "startupProbe" startupProbe;
          hasPreStop = isAttrs lifecycle && lifecycle ? preStop;
          effectiveRollout =
            if rollout == null then
              validateRollout
                {
                  strategy = {
                    type = "RollingUpdate";
                    rollingUpdate = { inherit maxSurge maxUnavailable; };
                  };
                }
            else
              validateRollout rollout;
          normalizedVolumes =
            if isList volumes then
              map normalizeVolume volumes
            else
              [ ];
          volumeNames = map (volume: volume.name) normalizedVolumes;
          volumeMountPaths = map (volume: volume.mountPath) normalizedVolumes;
          validatedSidecars =
            if isList sidecars then
              map (validateContainer "build.sidecars") sidecars
            else
              [ ];
          validatedTopologySpread =
            if isList topologySpread then
              map
                (constraint:
                  validateTopologySpreadConstraint constraint
                  // { labelSelector.matchLabels = labels; })
                topologySpread
            else
              [ ];
          topologySpreadKeys = map
            (constraint: "${constraint.topologyKey}/${constraint.whenUnsatisfiable}")
            validatedTopologySpread;
          managedPodSpecFields = [
            "affinity"
            "containers"
            "hostAliases"
            "imagePullSecrets"
            "initContainers"
            "nodeSelector"
            "serviceAccountName"
            "subdomain"
            "terminationGracePeriodSeconds"
            "tolerations"
            "topologySpreadConstraints"
            "volumes"
          ];
          extraPodSpecCollisions =
            if isAttrs extraPodSpec then
              filter (field: hasAttr field extraPodSpec) managedPodSpecFields
            else
              [ ];
          mainContainer = {
            inherit image name;
            env = env ++ (hex.envAttrToNVP envAttrs);
            ${ifNotEmptyList envFrom "envFrom"} = envFrom;
            ${ifNotNull command "command"} = if __init then [ "tail" ] else if builtins.isString command then [ command ] else command;
            ${ifNotNull args "args"} = if __init then [ "-f" "/dev/null" ] else args;
            ${ifNotNull validatedLivenessProbe "livenessProbe"} = validatedLivenessProbe;
            ${ifNotNull validatedReadinessProbe "readinessProbe"} = validatedReadinessProbe;
            ${ifNotNull validatedStartupProbe "startupProbe"} = validatedStartupProbe;
            ${ifNotNull sec_context "securityContext"} = sec_context;
            ${ifNotNull validatedLifecycle "lifecycle"} = validatedLifecycle;
            ${ifNotNull port "ports"} = [{
              containerPort = port;
              name = "application";
              protocol = "TCP";
            }];

            imagePullPolicy = "Always";
            resources = {
              ${if (memoryRequest != null || cpuRequest != null || ephemeralStorageRequest != null) then "requests" else null} = {
                ${ifNotNull cpuRequest "cpu"} = cpuRequest;
                ${ifNotNull memoryRequest "memory"} = memoryRequest;
                ${ifNotNull ephemeralStorageRequest "ephemeral-storage"} = ephemeralStorageRequest;
              };
              ${if (memoryLimit != null || cpuLimit != null || ephemeralStorageLimit != null) then "limits" else null} = {
                ${ifNotNull memoryLimit "memory"} = memoryLimit;
                ${ifNotNull cpuLimit "cpu"} = cpuLimit;
                ${ifNotNull ephemeralStorageLimit "ephemeral-storage"} = ephemeralStorageLimit;
              };
            };
            ${ifNotEmptyList normalizedVolumes "volumeMounts"} = map volumeMountDef normalizedVolumes;
          } // extraContainer;
          containerNames =
            [ mainContainer.name ]
            ++ (map (container: container.name) validatedSidecars)
            ++ (if tailscaleSidecar then [ "ts" ] else [ ]);
          podSpec = {
            ${ifNotEmptyAttr affinity "affinity"} = affinity;
            ${ifNotEmptyList imagePullSecrets "imagePullSecrets"} = imagePullSecrets;
            ${ifNotNull subdomain "subdomain"} = subdomain;
            ${ifNotNull nodeSelector "nodeSelector"} = nodeSelector;
            ${ifNotNull initContainers "initContainers"} = initContainers;
            ${ifNotNull tolerations "tolerations"} = tolerations;
            ${ifNotEmptyList validatedTopologySpread "topologySpreadConstraints"} = validatedTopologySpread;
            ${ifNotNull terminationGracePeriodSeconds "terminationGracePeriodSeconds"} = terminationGracePeriodSeconds;
            containers = [
              mainContainer
            ] ++ validatedSidecars ++ (if tailscaleSidecar then [{
              name = "ts";
              image = "${tailscale_image_base}:${tailscale_image_tag}";
              env = hex.envAttrToNVP {
                TS_KUBE_SECRET = "${name}${tsSuffix}";
                TS_USERSPACE = "false";
                TS_EXTRA_ARGS = ts_extra_args;
              };
              securityContext.capabilities.add = [ "NET_ADMIN" ];
            }] else [ ]);
            serviceAccountName = "${name}${saSuffix}";
            ${ifNotEmptyList normalizedVolumes "volumes"} = map volumeDef normalizedVolumes;
            ${ifNotEmptyList hostAliases "hostAliases"} = hostAliases;
          } // extraPodSpec;
        in
        assert assertMsg (terminationGracePeriodSeconds == null || (isInt terminationGracePeriodSeconds && terminationGracePeriodSeconds >= 0))
          "hex.k8s.services.build: terminationGracePeriodSeconds must be null or a non-negative integer";
        assert assertMsg (!(terminationGracePeriodSeconds == 0 && hasPreStop))
          "hex.k8s.services.build: lifecycle.preStop cannot be used when terminationGracePeriodSeconds is 0";
        assert assertMsg (isList volumes)
          "hex.k8s.services.build: volumes must be a list";
        assert assertMsg (volumeNames == pkgs.lib.unique volumeNames)
          "hex.k8s.services.build: volume names must be unique";
        assert assertMsg (volumeMountPaths == pkgs.lib.unique volumeMountPaths)
          "hex.k8s.services.build: volume mount paths must be unique";
        assert assertMsg (isList sidecars)
          "hex.k8s.services.build: sidecars must be a list";
        assert assertMsg (containerNames == pkgs.lib.unique containerNames)
          "hex.k8s.services.build: container names must be unique";
        assert assertMsg (isList topologySpread)
          "hex.k8s.services.build: topologySpread must be a list";
        assert assertMsg (topologySpreadKeys == pkgs.lib.unique topologySpreadKeys)
          "hex.k8s.services.build: topologySpread entries must have unique topologyKey and whenUnsatisfiable pairs";
        assert assertMsg (isAttrs extraPodSpec)
          "hex.k8s.services.build: extraPodSpec must be an attribute set";
        assert assertMsg (extraPodSpecCollisions == [ ])
          "hex.k8s.services.build: extraPodSpec cannot replace Hex-managed fields: ${concatStringsSep ", " extraPodSpecCollisions}";
        {
          apiVersion = "apps/v1";
          kind = if daemonSet then "DaemonSet" else "Deployment";
          metadata = {
            inherit namespace labels;
            name = depName;
            annotations = extraDeploymentAnnotations // hex.annotations;
          };
          spec = {
            inherit revisionHistoryLimit;
            selector = {
              matchLabels = labels;
            };
            ${if daemonSet then null else "replicas"} = replicas;
            ${if daemonSet then null else "strategy"} = effectiveRollout.strategy;
            ${if daemonSet || !(effectiveRollout ? minReadySeconds) then null else "minReadySeconds"} = effectiveRollout.minReadySeconds or null;
            ${if daemonSet || !(effectiveRollout ? progressDeadlineSeconds) then null else "progressDeadlineSeconds"} = effectiveRollout.progressDeadlineSeconds or null;
            template = {
              metadata = {
                inherit namespace labels;
                name = depName;
                annotations = {
                  ${if oldAppArmor then "container.apparmor.security.beta.kubernetes.io/${name}" else null} = appArmor;
                } // hex.annotations // extraPodAnnotations;
              };
              spec = podSpec;
            };
          };
        };
      ingress =
        { name
        , port
        , tls
        , host ? null
        , namespace ? "default"
        , ingressSuffix ? "-ingress"
        , serviceSuffix ? "-service"
        , pre1_18 ? false
        , disableHttp ? true
        , extraIngressAnnotations ? { }
        }: {
          apiVersion = if pre1_18 then "extensions/v1beta1" else "networking.k8s.io/v1";
          kind = "Ingress";
          metadata = {
            inherit namespace;
            name = "${name}${ingressSuffix}";
            labels = {
              name = "${name}${ingressSuffix}";
            };
            annotations = { } // (if disableHttp then {
              "kubernetes.io/ingress.allow-http" = "false";
            } else { }) // extraIngressAnnotations;
          };
          spec = {
            ${if pre1_18 then null else "defaultBackend"} = {
              service = {
                name = "${name}${serviceSuffix}";
                port = {
                  number = port;
                };
              };
            };
            ${if pre1_18 then "rules" else null} = [
              {
                ${ifNotNull host "host"} = host;
                http = {
                  paths = [
                    {
                      backend = {
                        service = {
                          name = "${name}${serviceSuffix}";
                          port.number = port;
                        };
                      };
                      path = "/";
                      pathType = "ImplementationSpecific";
                    }
                  ];
                };
              }
            ];
            tls = [
              {
                ${ifNotNull host "hosts"} = [
                  host
                ];
                secretName = tls;
              }
            ];
          };
        };

      pvc =
        { name
        , namespace ? "default"
        , accessModes ? [ "ReadWriteOnce" ]
        , storage ? "10Gi"
        , storageClass ? "standard"
        , extra ? { }
        }: {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            inherit name namespace;
          };
          spec = {
            inherit accessModes;
            resources = {
              requests = {
                inherit storage;
              };
            };
            storageClassName = storageClass;
          };
        } // extra;
    };
  };
in
services
