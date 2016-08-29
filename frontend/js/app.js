import React from 'react';
import ReactDOM from 'react-dom';
import Relay from 'react-relay';

class Task extends React.Component {
  render() {
    var {name, completed} = this.props.task;
    return <span>{completed ? <strike>{name}</strike> : name}</span>
  }
}
Task = Relay.createContainer(Task, {
  fragments: {
    task: () => Relay.QL`
      fragment on Task {
        name
        completed
      }
    `,
  },
});


class Project extends React.Component {
  render() {
    var {name} = this.props.project;
    return <span>{name}</span>
  }
}
Project = Relay.createContainer(Project, {
  fragments: {
    project: () => Relay.QL`
      fragment on Project {
        name
      }
    `,
  },
});

class Client extends React.Component {
  render() {
    var {name} = this.props.client;
    return <span>{name}</span>
  }
}
Client = Relay.createContainer(Client, {
  fragments: {
    client: () => Relay.QL`
      fragment on Client {
        name
      }
    `,
  },
});


class App extends React.Component {
  _handleCountChange = (e) => {
    this.props.relay.setVariables({
      clientsToShow: e.target.value
        ? parseInt(e.target.value, 10)
        : 0,
    });
  }
  _handleShowProjects = (e) => {
    var {showTasks} = this.props.relay.variables
    var showProjects = e.target.checked
    this.props.relay.setVariables({
      showProjects: showProjects,
      showTasks: showProjects && showTasks
    });
  }
  _handleShowTasks = (e) => {
    var {showProjects} = this.props.relay.variables
    var showTasks = e.target.checked
    this.props.relay.setVariables({
      showProjects: showProjects || showTasks,
      showTasks: showTasks
    });
  }
  _handleTaskCompletedChange = (e) => {
    var showTaskType = e.target.value
    var completed = null
    switch(showTaskType){
      case 'completed': completed = {op: 'eq', val: true}; break;
      case 'inprogress': completed = {op: 'eq', val: false}; break;
      default: completed = null;
    }
    this.props.relay.setVariables({
      completed: completed
    });
  }
  render() {
  	var {clientsToShow, showProjects, showTasks, completed} = this.props.relay.variables;
    var selectValue = 'all'
    var completedVal = completed && completed.val
    switch (completedVal) {
      case true:  selectValue = 'completed'; break;
      case false: selectValue = 'inprogress'; break;
      default: selectValue = 'all';
    }
    return <div>
    	<input
    	  onChange={this._handleCountChange}
          min="1"
          style={{width: 44}}
          type="number"
          value={clientsToShow}
        /> Clients to show
      <br />
      <input type="checkbox" checked={showProjects} onChange={this._handleShowProjects} /> Show Projects <br />
      <input type="checkbox" checked={showTasks} onChange={this._handleShowTasks}/> Show Tasks <br />
      {showTasks && <select value={selectValue} onChange={this._handleTaskCompletedChange}>
        <option value="all">All</option>
        <option value="completed">Completed</option>
        <option value="inprogress">In Progress</option>
      </select>}
      <ul>
        {this.props.viewer.clients.edges.map(
          client => <li key={client.node.id}>
            <Client client={client.node} />
            {showProjects && <ul>
              {client.node.projects.edges.map(
                project => <li key={project.node.id}>
                  <Project project={project.node} />
                  {showTasks && <ul>
                    {project.node.tasks.edges.map(
                      task => <li key={task.node.id}><Task task={task.node} /></li>
                    )}
                  </ul>}
                </li>
              )}
            </ul>}
          </li>
        )}
      </ul>
    </div>
    
  }
}
App = Relay.createContainer(App, {
  initialVariables: {
    clientsToShow: 3,
    showProjects: true,
    showTasks: false,
    completed: null,
  },
  fragments: {
    viewer: ({clientsToShow, showProjects, showTasks, showCompletedTasks, completed}) => Relay.QL`
      fragment on Viewer {
        clients(first: $clientsToShow) {
          edges {
            node {
              id
              ${Client.getFragment('client')}
              projects(first: 10) @include(if: $showProjects) {
                edges {
                  node {
                    id
                    ${Project.getFragment('project')}
                    tasks(first: 10, completed: $completed)  @include(if: $showTasks) {
                      edges {
                        node {
                          id
                          ${Task.getFragment('task')}
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    `,
  },
});


class AppHomeRoute extends Relay.Route {
  static routeName = 'Home';
  static queries = {
    viewer: (Component) => Relay.QL`
      query {
        viewer { ${Component.getFragment('viewer')} },
      }
    `,
  };
}

Relay.injectNetworkLayer(
  new Relay.DefaultNetworkLayer('/api/graphql', {
    headers: {
      Authorization: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW5pc3RyYXRvciIsInVzZXJfaWQiOjEsImNvbXBhbnlfaWQiOjF9.ate5mETtGRu-mfGF4jFt7pP1b4W85r2uEXt603D7obc',
    }
  })
);

ReactDOM.render(
  <Relay.RootContainer
  	environment={Relay.Store}
    Component={App}
    route={new AppHomeRoute()}
  />,
  document.getElementById('root')
);