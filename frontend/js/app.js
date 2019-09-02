var app = angular.module('NoMongo', ['main', 'ui.router', 'ngSanitize', 'ngMaterial', 'ngMessages', 'ngMaterialAccordion']);

app.constant('$config', {
    url: 'http://142.93.75.2',
    pagination: 'server'
});


app.config(function($stateProvider, $urlRouterProvider, $locationProvider) {

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
            templateUrl : 'signout/signout.component.html',
            controller : 'signoutCtrl'
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
}]);


angular.module("main",[]);


app.controller("signinCtrl", function($sce, $scope, $state, $http, $config, $mdToast){
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
                console.log('Sucesso: ', response);
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

app.controller("mainCtrl", function($scope, $state, $mdSidenav, menuService){
    
    $scope.isSidenavOpen = false;
    $scope.toggleLeft = buildToggler('left');

    function buildToggler(componentId) {
      return function() {
        $mdSidenav(componentId).toggle();
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


angular.module("main").controller("mainController",function($scope){

    
});



