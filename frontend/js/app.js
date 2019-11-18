var app = angular.module('NoMongo', ['main', 'ui.router', 'ngSanitize', 'ngMaterial', 'ngMessages', 'ngMaterialAccordion']);

app.constant('$config', {
    url: 'http://127.0.0.1',
    pagination: 'server'
});


angular.module("main",[]);


app.controller("signinCtrl", function($sce, $scope, $state, $http, $config, $mdToast, $session){
    $scope.submit = function() {
        if(! $scope.username) {
            alert("Você não informou um usuário");
            return false;
        }
        if(! $scope.password) {
            alert("Você não informou uma senha");
            return false;
        }
        
        var send = {
            username: $scope.username,
            password: $scope.password
        };
        
        $http.post($config.url+'/sys/signin', send)
            .then(function(response) {
                $session.create(response.data.sid, response.data.user);
                $http.defaults.headers.common['sid'] = response.data.sid;
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent('Bem vindo, ' + response.data.user.name)
                    .theme('success-toast')
                    .hideDelay(2000));
                $state.go('home', { reload: true});
            }, function errorCallback(response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('error-toast')
                    .hideDelay(2000));
            });
    }
    
});

app.controller("signoutCtrl", function($session, $state){
    $session.destroy();
    $state.go('signin');
});

app.controller("mainCtrl", function($scope, $state, $mdSidenav, menuService, $session){
    
    $scope.isSidenavOpen = false;
    $scope.toggleLeft = buildToggler('left');

    function buildToggler(componentId) {
        return function() {
            if($session.get('sid')) {
                $mdSidenav(componentId).toggle();
            } else {
                $state.go('signin');
            }
        };
    }
    
    menuService.get().then(function (response){
        var data = response.data[0];
        var posload = false;

        $scope.menu = response.data;
        console.log('Menu: ', $scope.menu);
    });
});

app.controller("homeCtrl", function($scope, $state){
    

});

app.controller("defaultCtrl", function($sce, $scope, $state, $api, $mdToast, $mdDialog){
    this.columns = $state.current.render.columns;
    this.data = $state.current.render.data;
    var resource = $state.current.render.resource;
    $scope.val = {};
    $scope.selectedIndex = 0;

    $api.read(resource).then(function (response) {
        $scope.fetch = response.data;
    }, function (response) {
        if(response.data) {
            response = response.data;
        }
        var decoded = angular.element('<textarea />').html(response.message).text();
        $mdToast.show(
            $mdToast.simple()
            .position('top right')
            .textContent($sce.trustAsHtml(decoded))
            .theme('error-toast')
            .hideDelay(5000));       
    });
    
    $scope.reload = function() {
        $scope.editId = -1;
        $api.read(resource).then(function (response) {
            $scope.fetch = response.data;
        });
        $scope.selectedIndex = 0;
    }
    
    $scope.load = function(editId) {
        $scope.editId = editId;
        $scope.val = {};
        $api.read(resource, editId).then(function (response) {
            var data = response.data[0];
            if(data){
                angular.forEach(data, function(value, key) {
                    $scope.val[key] = value;
                });
                $scope.selectedIndex = 1;
            }
        });
    }
    
    $scope.delete = function(event, editId) {
        var confirm = $mdDialog.confirm()
            .title('Confirma exclusão?')
            .textContent('Essa operação não pode ser revertida, você tem certeza que deseja excluir o registro?')
            .targetEvent(event)
            .ok('Confirmar')
            .cancel('Cancelar');

        $mdDialog.show(confirm).then(function() {
            $api.delete(resource, editId).then(function (response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('success-toast')
                    .hideDelay(2000));
                $scope.reload();
            }, function (response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('error-toast')
                    .hideDelay(2000));
            });
        }, function() {
            $scope.reload();
        });
    }
    
    
    $scope.submit = function() {
        var editId = $scope.editId;
        var send = {};
        angular.forEach($scope.val, function(value, key){
            if(typeof value !== 'undefined') {
                if(value.selectedOption) {
                    send[key] = value.selectedOption.id;
                } else {
                    send[key] = value;
                }
            }
        });
        
        if(editId) {
            $api.update(resource, send, editId).then(function (response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('success-toast')
                    .hideDelay(2000));
                $scope.reload();
            }, function (response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('error-toast')
                    .hideDelay(2000));
                });           
        } else {
            $api.create(resource, send).then(function (response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('success-toast')
                    .hideDelay(2000));
                $scope.reload();
            }, function (response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('error-toast')
                    .hideDelay(2000));
                });           
            }
        }
    });

app.run(function($window, $session, $http) {
    if($session.get('sid')) {
        $http.defaults.headers.common['sid'] = $session.get('sid');
    }
});

angular.module("main").controller("mainController",function($scope){

    
});



