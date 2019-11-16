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
                console.log('Erro: ', response);
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

app.controller("defaultCtrl", function($scope, $state, $api, $mdToast){
    this.columns = $state.current.render.columns;
    this.data = $state.current.render.data;
    var resource = $state.current.render.resource;
    
    $api.get(resource).then(function (response) {
        $scope.fetch = response.data;
    });
    
    $scope.load = function(editId) {
        $api.get(resource, editId).then(function (response) {
            var data = response.data[0];
            if(data){
                angular.forEach(data, function(value, key) {
                    $scope.fetch[key] = value;
                });
            }
        });
    }
    
    $scope.submit = function() {
        if($scope.editId) {
            $api.update(resource).then(function (response) {
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent(response.data.message)
                    .theme('success-toast')
                    .hideDelay(2000));
            });
        } else {
            $api.insert(resource).then(function (response) {
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent(response.data.message)
                    .theme('success-toast')
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



