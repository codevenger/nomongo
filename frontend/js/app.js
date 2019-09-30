var app = angular.module('NoMongo', ['main', 'ui.router', 'ngSanitize', 'ngMaterial', 'ngMessages', 'ngMaterialAccordion']);

app.constant('$config', {
    url: 'http://142.93.75.2',
    pagination: 'server'
});


app.config(function($stateProvider, $urlRouterProvider, $locationProvider, $config) {

    $urlRouterProvider.otherwise('/signin');
    
    var main = {
        name: 'main',
        url: '/main',
        templateUrl: 'main.component.html',
        controller: 'mainCtrl'
    }
    
    $stateProvider.state(main);

    $stateProvider
    
        .state('signin', {
            url: '/signin',
            templateUrl : 'signin/signin.component.html',
            controller : 'signinCtrl'
        })

        .state('home', {
            parent: main,
            url: '/home',
            templateUrl : 'home/home.component.html',
            controller : 'homeCtrl'
        })

        .state('signout', {
            url: '/signout',
            templateUrl : 'signin/signin.component.html',
            controller : 'signoutCtrl'
        })
        
        .state('groups', {
            parent: main,
            url: '/groups',
            templateUrl: '/groups'
        })
        
        .state('users', {
            parent: main,
            url: '/users',
            templateUrl: '/users'
        });
        
    
});

app.service('menuService', ['$http', '$q', '$state', '$mdToast', '$config', '$sce', function($http, $q, $state, $mdToast, $config, $sce){
    this.get = function(id){
        var deferred = $q.defer();
        $http.get($config.url+'/sys/menu').
            then(function(response) {
                deferred.resolve(response);
            }, function errorCallback(response) {
                if(response.status == 401) {
                    $state.go('signin');
                } else if(response.status == 500) {
                    $mdToast.show(
                        $mdToast.simple()
                        .position('top right')
                        .textContent('Recurso está indisponível')
                        .theme('error-toast')
                        .hideDelay(2000));                    
                }else {
                    if(response.data) {
                        response = response.data;
                    }
                    if(response.message) {
                        response = response.message;
                    }
                    var decoded = angular.element('<textarea />').html(response).text();
                    $mdToast.show(
                        $mdToast.simple()
                        .position('top right')
                        .textContent($sce.trustAsHtml(decoded))
                        .theme('error-toast')
                        .hideDelay(2000));
                    console.log('Erro: ', response);
                }
            });
        return deferred.promise;
    }
}])

.service('$session', function () {
    this.create = function (sid, user) {
        this.sid = sid;
        this.user = user;
    
        window.sessionStorage.setItem('sid', sid);
        window.sessionStorage.setItem('user', user);
    };
    this.set = function (k, v) {
        window.sessionStorage.setItem(k, v);
    };
    this.get = function (k) {
        return window.sessionStorage.getItem(k);
    };
    this.destroy = function () {
        this.sid = null;
        this.user = null;
        
        window.sessionStorage.removeItem('sid');
        window.sessionStorage.removeItem('user');
    };
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
    
    menuService.get().then(function (response) {
        var data = response.data[0];
        var posload = false;

        $scope.menu = response.data;
        console.log('Menu: ', $scope.menu);
    });
});

app.controller("homeCtrl", function($scope, $state){
    

});

app.run(function($window, $session, $http) {
    if($session.get('sid')) {
        $http.defaults.headers.common['sid'] = $session.get('sid');
    }
});

angular.module("main").controller("mainController",function($scope){

    
});



